import uuid
from datetime import date, timedelta
from typing import List, Optional
from decimal import Decimal
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.property import Property, PropertyType
from app.models.room import RoomType, RoomAllocation
from app.models.guide import LocalGuide, ResortGuideAssociation
from app.models.booking import Reservation
from app.models.user import VendorProfile
from app.schemas.property import PropertyCreate, PropertyUpdate, PropertyDetailResponse
from app.schemas.room import RoomTypeCreate, RoomTypeUpdate, RoomAllocationBatchCreate, RoomAllocationResponse


class VendorService:
    @staticmethod
    async def get_vendor_profile(db: AsyncSession, user_id: uuid.UUID) -> VendorProfile:
        stmt = select(VendorProfile).where(VendorProfile.user_id == user_id)
        result = await db.execute(stmt)
        profile = result.scalar_one_or_none()
        if not profile:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vendor profile not found.")
        return profile

    @classmethod
    async def get_vendor_properties(cls, db: AsyncSession, vendor_id: uuid.UUID) -> List[Property]:
        stmt = (
            select(Property)
            .where(Property.vendor_id == vendor_id)
            .options(selectinload(Property.room_types))
        )
        result = await db.execute(stmt)
        return result.scalars().all()

    @classmethod
    async def create_property(cls, db: AsyncSession, vendor_id: uuid.UUID, prop_in: PropertyCreate) -> Property:
        slug = prop_in.name.lower().replace(" ", "-").replace("&", "and")
        # Check slug collision
        stmt = select(Property).where(Property.slug == slug)
        res = await db.execute(stmt)
        if res.scalar_one_or_none():
            slug = f"{slug}-{uuid.uuid4().hex[:6]}"

        prop = Property(
            vendor_id=vendor_id,
            property_type=prop_in.property_type,
            name=prop_in.name,
            slug=slug,
            description=prop_in.description,
            tagline=prop_in.tagline,
            address=prop_in.address,
            city=prop_in.city,
            state=prop_in.state,
            country=prop_in.country,
            postal_code=prop_in.postal_code,
            latitude=prop_in.latitude,
            longitude=prop_in.longitude,
            star_rating=prop_in.star_rating,
            cover_image_url=prop_in.cover_image_url,
            gallery_images=prop_in.gallery_images,
            amenities=prop_in.amenities,
            check_in_time=prop_in.check_in_time,
            check_out_time=prop_in.check_out_time,
            cancellation_policy=prop_in.cancellation_policy,
            is_published=prop_in.is_published,
        )
        db.add(prop)
        await db.commit()
        await db.refresh(prop)
        return prop


    @classmethod
    async def update_property(cls, db: AsyncSession, vendor_id: uuid.UUID, property_id: uuid.UUID, prop_in: PropertyUpdate) -> Property:
        stmt = select(Property).where(Property.id == property_id, Property.vendor_id == vendor_id)
        res = await db.execute(stmt)
        prop = res.scalar_one_or_none()
        if not prop:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found or unauthorized.")
        
        update_data = prop_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(prop, field, value)
            
        await db.commit()
        await db.refresh(prop)
        return prop

    @classmethod
    async def delete_property(cls, db: AsyncSession, vendor_id: uuid.UUID, property_id: uuid.UUID) -> bool:
        stmt = select(Property).where(Property.id == property_id, Property.vendor_id == vendor_id)
        res = await db.execute(stmt)
        prop = res.scalar_one_or_none()
        if not prop:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found or unauthorized.")
        
        prop.is_published = False
        await db.commit()
        return True

    @classmethod
    async def update_room_type(cls, db: AsyncSession, vendor_id: uuid.UUID, room_id: uuid.UUID, room_in: RoomTypeUpdate) -> RoomType:
        stmt = select(RoomType).join(Property).where(RoomType.id == room_id, Property.vendor_id == vendor_id)
        res = await db.execute(stmt)
        room = res.scalar_one_or_none()
        if not room:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room type not found or unauthorized.")
            
        update_data = room_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(room, field, value)
            
        await db.commit()
        await db.refresh(room)
        return room

    @classmethod
    async def delete_room_type(cls, db: AsyncSession, vendor_id: uuid.UUID, room_id: uuid.UUID) -> bool:
        stmt = select(RoomType).join(Property).where(RoomType.id == room_id, Property.vendor_id == vendor_id)
        res = await db.execute(stmt)
        room = res.scalar_one_or_none()
        if not room:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room type not found or unauthorized.")
            
        room.is_active = False
        await db.commit()
        return True
        
    @classmethod
    async def get_allocations(cls, db: AsyncSession, vendor_id: uuid.UUID, room_type_id: uuid.UUID, start_date: date, end_date: date) -> List[RoomAllocationResponse]:
        stmt = select(RoomType).join(Property).where(RoomType.id == room_type_id, Property.vendor_id == vendor_id)
        res = await db.execute(stmt)
        room = res.scalar_one_or_none()
        if not room:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized for this room type.")
            
        alloc_stmt = select(RoomAllocation).where(
            RoomAllocation.room_type_id == room_type_id,
            RoomAllocation.allocation_date >= start_date,
            RoomAllocation.allocation_date <= end_date
        ).order_by(RoomAllocation.allocation_date)
        
        alloc_res = await db.execute(alloc_stmt)
        allocations = alloc_res.scalars().all()
        
        return [
            RoomAllocationResponse(
                id=a.id,
                room_type_id=a.room_type_id,
                allocation_date=a.allocation_date,
                total_allocated=a.total_allocated,
                booked_count=a.booked_count,
                available_count=max(0, a.total_allocated - a.booked_count),
                rate_multiplier=a.rate_multiplier,
                effective_price=room.base_price_per_night * a.rate_multiplier,
                is_closed=a.is_closed
            ) for a in allocations
        ]

    @classmethod
    async def create_room_type(cls, db: AsyncSession, vendor_id: uuid.UUID, room_in: RoomTypeCreate) -> RoomType:
        stmt = select(Property).where(Property.id == room_in.property_id, Property.vendor_id == vendor_id)
        res = await db.execute(stmt)
        if not res.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Property does not belong to vendor.")

        room = RoomType(
            property_id=room_in.property_id,
            name=room_in.name,
            description=room_in.description,
            max_occupancy=room_in.max_occupancy,
            bed_configuration=room_in.bed_configuration,
            base_price_per_night=room_in.base_price_per_night,
            amenities=room_in.amenities,
            images=room_in.images,
            is_active=room_in.is_active,
        )
        db.add(room)
        await db.commit()
        await db.refresh(room)
        return room

    @classmethod
    async def set_room_allocations_batch(
        cls, db: AsyncSession, vendor_id: uuid.UUID, batch_in: RoomAllocationBatchCreate
    ) -> List[RoomAllocationResponse]:
        # Verify room belongs to vendor property
        stmt = (
            select(RoomType)
            .join(Property, RoomType.property_id == Property.id)
            .where(RoomType.id == batch_in.room_type_id, Property.vendor_id == vendor_id)
        )
        res = await db.execute(stmt)
        room = res.scalar_one_or_none()
        if not room:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized for this room type.")

        days = (batch_in.end_date - batch_in.start_date).days
        if days < 0:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="End date must be after start date.")

        allocations: List[RoomAllocationResponse] = []

        for d_idx in range(days + 1):
            target_date = batch_in.start_date + timedelta(days=d_idx)

            # Check existing allocation
            alloc_stmt = select(RoomAllocation).where(
                RoomAllocation.room_type_id == room.id,
                RoomAllocation.allocation_date == target_date,
            )
            alloc_res = await db.execute(alloc_stmt)
            existing_alloc = alloc_res.scalar_one_or_none()

            if existing_alloc:
                existing_alloc.total_allocated = batch_in.total_allocated
                existing_alloc.rate_multiplier = batch_in.rate_multiplier
                existing_alloc.is_closed = batch_in.is_closed
                db_alloc = existing_alloc
            else:
                db_alloc = RoomAllocation(
                    room_type_id=room.id,
                    allocation_date=target_date,
                    total_allocated=batch_in.total_allocated,
                    booked_count=0,
                    rate_multiplier=batch_in.rate_multiplier,
                    is_closed=batch_in.is_closed,
                )
                db.add(db_alloc)

            await db.flush()

            allocations.append(
                RoomAllocationResponse(
                    id=db_alloc.id,
                    room_type_id=db_alloc.room_type_id,
                    allocation_date=db_alloc.allocation_date,
                    total_allocated=db_alloc.total_allocated,
                    booked_count=db_alloc.booked_count,
                    available_count=max(0, db_alloc.total_allocated - db_alloc.booked_count),
                    rate_multiplier=db_alloc.rate_multiplier,
                    effective_price=room.base_price_per_night * db_alloc.rate_multiplier,
                    is_closed=db_alloc.is_closed,
                )
            )

        await db.commit()
        return allocations

    @classmethod
    async def link_guide_to_resort(
        cls, db: AsyncSession, vendor_id: uuid.UUID, resort_id: uuid.UUID, guide_id: uuid.UUID, is_primary: bool = False
    ) -> bool:
        stmt = select(Property).where(
            Property.id == resort_id,
            Property.vendor_id == vendor_id,
            Property.property_type == PropertyType.RESORT,
        )
        res = await db.execute(stmt)
        if not res.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Resort not found or unauthorized.")

        assoc_stmt = select(ResortGuideAssociation).where(
            ResortGuideAssociation.resort_id == resort_id,
            ResortGuideAssociation.guide_id == guide_id,
        )
        assoc_res = await db.execute(assoc_stmt)
        existing = assoc_res.scalar_one_or_none()

        if existing:
            existing.is_primary = is_primary
        else:
            assoc = ResortGuideAssociation(resort_id=resort_id, guide_id=guide_id, is_primary=is_primary)
            db.add(assoc)

        await db.commit()
        return True
