import uuid
from datetime import date, timedelta
from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.api.deps import get_current_active_admin
from app.models.user import User, VendorProfile
from app.models.property import Property, PropertyType
from app.models.room import RoomType, RoomAllocation
from app.models.guide import LocalGuide
from app.models.booking import Reservation, BookingStatus
from app.schemas.common import APIResponse
from app.schemas.property import PropertyCreate, PropertyUpdate
from app.schemas.room import RoomTypeBase, RoomTypeUpdate

router = APIRouter()


# =============================================================================
# 1. ADMIN TELEMETRY & SYSTEM OVERVIEW
# =============================================================================

@router.get("/overview", response_model=APIResponse[dict])
async def get_admin_overview(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Internal Admin Dashboard: Ecosystem Telemetry & Aggregated Metrics.
    """
    total_users_res = await db.execute(select(func.count(User.id)))
    total_users = total_users_res.scalar() or 0

    total_hotels_res = await db.execute(
        select(func.count(Property.id)).where(Property.property_type == PropertyType.HOTEL)
    )
    total_hotels = total_hotels_res.scalar() or 0

    total_resorts_res = await db.execute(
        select(func.count(Property.id)).where(Property.property_type == PropertyType.RESORT)
    )
    total_resorts = total_resorts_res.scalar() or 0

    total_guides_res = await db.execute(select(func.count(LocalGuide.id)))
    total_guides = total_guides_res.scalar() or 0

    total_res_stmt = select(
        func.count(Reservation.id),
        func.coalesce(func.sum(Reservation.total_amount), 0.0),
        func.coalesce(func.sum(Reservation.platform_fee), 0.0),
    ).where(Reservation.status == BookingStatus.CONFIRMED)
    res_stats = (await db.execute(total_res_stmt)).one()

    return APIResponse(
        data={
            "total_users": total_users,
            "total_hotels": total_hotels,
            "total_resorts": total_resorts,
            "total_guides": total_guides,
            "confirmed_bookings": res_stats[0],
            "gross_booking_volume": float(res_stats[1]),
            "total_platform_revenue": float(res_stats[2]),
        }
    )


# =============================================================================
# 2. LOCAL GUIDE CERTIFICATION & VERIFICATION
# =============================================================================

@router.patch("/guides/{guide_id}/verify", response_model=APIResponse[dict])
async def toggle_guide_verification(
    guide_id: uuid.UUID,
    is_verified: bool,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    stmt = select(LocalGuide).where(LocalGuide.id == guide_id)
    res = await db.execute(stmt)
    guide = res.scalar_one_or_none()
    if not guide:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Local Guide not found.")
    guide.is_verified = is_verified
    await db.commit()
    return APIResponse(
        message=f"Local Guide verification status updated to {is_verified}.",
        data={"guide_id": str(guide.id), "is_verified": guide.is_verified},
    )


# =============================================================================
# 3. ADMIN PROPERTY INVENTORY CRUD (HOTELS & RESORTS)
# =============================================================================

@router.get("/properties", response_model=APIResponse[List[dict]])
async def list_admin_properties(
    property_type: Optional[PropertyType] = Query(None),
    search: Optional[str] = Query(None),
    is_published: Optional[bool] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    List all platform properties across all vendors with comprehensive inventory,
    pricing, room types, and publish status.
    """
    stmt = select(Property).options(selectinload(Property.room_types))

    if property_type:
        stmt = stmt.where(Property.property_type == property_type)
    if is_published is not None:
        stmt = stmt.where(Property.is_published == is_published)
    if search:
        search_term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Property.name.ilike(search_term),
                Property.city.ilike(search_term),
                Property.country.ilike(search_term),
                Property.tagline.ilike(search_term),
            )
        )

    stmt = stmt.order_by(Property.created_at.desc())
    res = await db.execute(stmt)
    properties = res.scalars().all()

    data = []
    for p in properties:
        active_rooms = [r for r in p.room_types if r.is_active]
        prices = [float(r.base_price_per_night) for r in active_rooms] if active_rooms else [
            float(r.base_price_per_night) for r in p.room_types
        ]
        min_price = min(prices) if prices else 0.0

        data.append({
            "id": str(p.id),
            "vendor_id": str(p.vendor_id),
            "property_type": p.property_type.value,
            "name": p.name,
            "slug": p.slug,
            "tagline": p.tagline,
            "description": p.description,
            "address": p.address,
            "city": p.city,
            "state": p.state,
            "country": p.country,
            "postal_code": p.postal_code,
            "latitude": float(p.latitude),
            "longitude": float(p.longitude),
            "star_rating": float(p.star_rating),
            "review_score": float(p.review_score),
            "review_count": p.review_count,
            "cover_image_url": p.cover_image_url,
            "gallery_images": p.gallery_images or [],
            "amenities": p.amenities or [],
            "check_in_time": p.check_in_time.strftime("%H:%M:%S") if p.check_in_time else "15:00:00",
            "check_out_time": p.check_out_time.strftime("%H:%M:%S") if p.check_out_time else "11:00:00",
            "cancellation_policy": p.cancellation_policy,
            "is_published": p.is_published,
            "room_types_count": len(p.room_types),
            "starting_price": min_price,
            "room_types": [
                {
                    "id": str(r.id),
                    "property_id": str(r.property_id),
                    "name": r.name,
                    "description": r.description,
                    "max_occupancy": r.max_occupancy,
                    "bed_configuration": r.bed_configuration,
                    "base_price_per_night": float(r.base_price_per_night),
                    "amenities": r.amenities or [],
                    "images": r.images or [],
                    "is_active": r.is_active,
                }
                for r in p.room_types
            ],
            "created_at": p.created_at.isoformat() if p.created_at else None,
        })

    return APIResponse(data=data)


@router.get("/properties/{property_id}", response_model=APIResponse[dict])
async def get_admin_property(
    property_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Get full property details including room types and pricing.
    """
    stmt = select(Property).where(Property.id == property_id).options(selectinload(Property.room_types))
    res = await db.execute(stmt)
    p = res.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found.")

    active_rooms = [r for r in p.room_types if r.is_active]
    prices = [float(r.base_price_per_night) for r in active_rooms] if active_rooms else [
        float(r.base_price_per_night) for r in p.room_types
    ]
    min_price = min(prices) if prices else 0.0

    return APIResponse(
        data={
            "id": str(p.id),
            "vendor_id": str(p.vendor_id),
            "property_type": p.property_type.value,
            "name": p.name,
            "slug": p.slug,
            "tagline": p.tagline,
            "description": p.description,
            "address": p.address,
            "city": p.city,
            "state": p.state,
            "country": p.country,
            "postal_code": p.postal_code,
            "latitude": float(p.latitude),
            "longitude": float(p.longitude),
            "star_rating": float(p.star_rating),
            "review_score": float(p.review_score),
            "review_count": p.review_count,
            "cover_image_url": p.cover_image_url,
            "gallery_images": p.gallery_images or [],
            "amenities": p.amenities or [],
            "check_in_time": p.check_in_time.strftime("%H:%M:%S") if p.check_in_time else "15:00:00",
            "check_out_time": p.check_out_time.strftime("%H:%M:%S") if p.check_out_time else "11:00:00",
            "cancellation_policy": p.cancellation_policy,
            "is_published": p.is_published,
            "starting_price": min_price,
            "room_types": [
                {
                    "id": str(r.id),
                    "property_id": str(r.property_id),
                    "name": r.name,
                    "description": r.description,
                    "max_occupancy": r.max_occupancy,
                    "bed_configuration": r.bed_configuration,
                    "base_price_per_night": float(r.base_price_per_night),
                    "amenities": r.amenities or [],
                    "images": r.images or [],
                    "is_active": r.is_active,
                }
                for r in p.room_types
            ],
            "created_at": p.created_at.isoformat() if p.created_at else None,
        }
    )


@router.post("/properties", response_model=APIResponse[dict], status_code=status.HTTP_201_CREATED)
async def create_admin_property(
    prop_in: PropertyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Create a new Hotel or Resort with full field specifications.
    Defaults to the primary vendor profile if vendor_id is omitted.
    """
    vendor_id = prop_in.vendor_id
    if not vendor_id:
        v_res = await db.execute(select(VendorProfile))
        v_profile = v_res.scalars().first()
        if not v_profile:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No vendor profile exists in the system to assign this property to.",
            )
        vendor_id = v_profile.id

    slug = prop_in.name.lower().replace(" ", "-").replace("&", "and")
    existing_slug = await db.execute(select(Property).where(Property.slug == slug))
    if existing_slug.scalar_one_or_none():
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

    return APIResponse(
        message=f"Property '{prop.name}' created successfully.",
        data={"id": str(prop.id), "name": prop.name, "slug": prop.slug, "type": prop.property_type.value},
    )


@router.patch("/properties/{property_id}", response_model=APIResponse[dict])
async def update_admin_property(
    property_id: uuid.UUID,
    prop_in: PropertyUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Update any and all fields of a Hotel or Resort: name, type, tagline, description,
    location coordinates, star rating, cover image, amenities, operational times, and policies.
    """
    stmt = select(Property).where(Property.id == property_id)
    res = await db.execute(stmt)
    prop = res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found.")

    update_data = prop_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(prop, field, value)

    await db.commit()
    await db.refresh(prop)
    return APIResponse(
        message=f"Property '{prop.name}' updated successfully.",
        data={
            "id": str(prop.id),
            "name": prop.name,
            "property_type": prop.property_type.value,
            "is_published": prop.is_published,
        },
    )


@router.patch("/properties/{property_id}/publish", response_model=APIResponse[dict])
async def publish_property(
    property_id: uuid.UUID,
    is_published: bool = Query(True),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Quick toggle to publish or unpublish a property from the consumer web search.
    """
    stmt = select(Property).where(Property.id == property_id)
    res = await db.execute(stmt)
    prop = res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found.")
    prop.is_published = is_published
    await db.commit()
    action = "published" if is_published else "unpublished"
    return APIResponse(message=f"Property {action} successfully.", data={"id": str(prop.id), "is_published": prop.is_published})


@router.delete("/properties/{property_id}", response_model=APIResponse[dict])
async def delete_admin_property(
    property_id: uuid.UUID,
    hard_delete: bool = Query(False),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Delete or unpublish a property. By default, performs safe unpublishing.
    If hard_delete=True, removes the property and cascades to room types and allocations.
    """
    stmt = (
        select(Property)
        .where(Property.id == property_id)
        .options(selectinload(Property.reservations))
    )
    res = await db.execute(stmt)
    prop = res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found.")

    if hard_delete:
        if prop.reservations:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot permanently delete a property with existing guest reservations. Use unpublish instead.",
            )
        await db.delete(prop)
        await db.commit()
        return APIResponse(message=f"Property '{prop.name}' permanently deleted.", data={"id": str(property_id)})
    else:
        prop.is_published = False
        await db.commit()
        return APIResponse(
            message=f"Property '{prop.name}' unpublished safely.",
            data={"id": str(property_id), "is_published": False},
        )


# =============================================================================
# 4. ADMIN ROOM TYPES & PRICING CRUD
# =============================================================================

@router.post("/properties/{property_id}/rooms", response_model=APIResponse[dict], status_code=status.HTTP_201_CREATED)
async def create_admin_room(
    property_id: uuid.UUID,
    room_in: RoomTypeBase,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Create a new room type for a property and automatically seed 90 days of room allocations
    (10 rooms per night) so it is immediately searchable and bookable by travelers.
    """
    prop_stmt = select(Property).where(Property.id == property_id)
    prop_res = await db.execute(prop_stmt)
    prop = prop_res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found.")

    room = RoomType(
        property_id=property_id,
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

    # Seed 90 days of inventory
    today = date.today()
    allocations = [
        RoomAllocation(
            room_type_id=room.id,
            allocation_date=today + timedelta(days=i),
            total_allocated=10,
            booked_count=0,
            rate_multiplier=Decimal("1.00"),
            is_closed=False,
        )
        for i in range(90)
    ]
    db.add_all(allocations)
    await db.commit()

    return APIResponse(
        message=f"Room '{room.name}' created and seeded with 90 days inventory.",
        data={
            "id": str(room.id),
            "property_id": str(room.property_id),
            "name": room.name,
            "base_price_per_night": float(room.base_price_per_night),
            "max_occupancy": room.max_occupancy,
            "is_active": room.is_active,
        },
    )


@router.patch("/rooms/{room_id}", response_model=APIResponse[dict])
async def update_admin_room(
    room_id: uuid.UUID,
    room_in: RoomTypeUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Update room type details including nightly price, occupancy, bed configuration,
    amenities, images, and active status.
    """
    stmt = select(RoomType).where(RoomType.id == room_id)
    res = await db.execute(stmt)
    room = res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room type not found.")

    update_data = room_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(room, field, value)

    await db.commit()
    await db.refresh(room)
    return APIResponse(
        message=f"Room '{room.name}' updated successfully.",
        data={
            "id": str(room.id),
            "property_id": str(room.property_id),
            "name": room.name,
            "base_price_per_night": float(room.base_price_per_night),
            "max_occupancy": room.max_occupancy,
            "bed_configuration": room.bed_configuration,
            "is_active": room.is_active,
        },
    )


@router.delete("/rooms/{room_id}", response_model=APIResponse[dict])
async def delete_admin_room(
    room_id: uuid.UUID,
    hard_delete: bool = Query(False),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Deactivate or permanently delete a room type.
    """
    stmt = select(RoomType).where(RoomType.id == room_id).options(selectinload(RoomType.booking_items))
    res = await db.execute(stmt)
    room = res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room type not found.")

    if hard_delete:
        if room.booking_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot delete room type with past reservations. Deactivate it instead.",
            )
        await db.delete(room)
        await db.commit()
        return APIResponse(message=f"Room '{room.name}' permanently deleted.", data={"id": str(room_id)})
    else:
        room.is_active = False
        await db.commit()
        return APIResponse(
            message=f"Room '{room.name}' deactivated successfully.",
            data={"id": str(room_id), "is_active": False},
        )
