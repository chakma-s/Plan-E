import uuid
from datetime import date, timedelta
from typing import List, Optional
from decimal import Decimal
from sqlalchemy import select, and_, or_, func
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.property import Property, PropertyType
from app.models.room import RoomType, RoomAllocation
from app.schemas.property import (
    HotelSearchParams,
    HotelCardResponse,
    PropertyDetailResponse,
)
from app.schemas.room import RoomTypeResponse


class HotelService:
    """
    Dedicated Hotel Pipeline.
    Optimized for transactional speed, lean payload transfers, and rapid filtering.
    """

    @staticmethod
    async def search_hotels(db: AsyncSession, params: HotelSearchParams) -> List[HotelCardResponse]:
        query = select(Property).where(
            Property.property_type == PropertyType.HOTEL,
            Property.is_published == True,
        ).options(
            selectinload(Property.room_types).selectinload(RoomType.allocations)
        )

        # 1. City / Keyword Filter
        if params.city:
            city_filter = f"%{params.city.strip().lower()}%"
            query = query.where(
                or_(
                    func.lower(Property.city).like(city_filter),
                    func.lower(Property.name).like(city_filter),
                    func.lower(Property.address).like(city_filter),
                )
            )

        # 2. Mapbox Bounding Box Spatial Filter
        if params.min_lat is not None and params.max_lat is not None:
            query = query.where(
                Property.latitude >= params.min_lat,
                Property.latitude <= params.max_lat,
            )
        if params.min_lon is not None and params.max_lon is not None:
            query = query.where(
                Property.longitude >= params.min_lon,
                Property.longitude <= params.max_lon,
            )

        # 3. Minimum Star / Review Rating Filter
        if params.min_rating is not None:
            query = query.where(Property.star_rating >= params.min_rating)

        result = await db.execute(query)
        properties = result.scalars().all()

        check_in = params.check_in
        check_out = params.check_out

        cards: List[HotelCardResponse] = []

        for prop in properties:
            # Determine minimum room price and availability across dates
            min_price: Optional[Decimal] = None
            is_available = True

            active_room_types = [rt for rt in prop.room_types if rt.is_active and rt.max_occupancy >= params.guests]
            if not active_room_types:
                continue

            available_room_prices = []

            for rt in active_room_types:
                if check_in and check_out:
                    # Verify daily allocation for all nights in date range
                    stay_days = (check_out - check_in).days
                    if stay_days <= 0:
                        stay_days = 1

                    allocations_by_date = {
                        alloc.allocation_date: alloc for alloc in rt.allocations if not alloc.is_closed
                    }
                    
                    room_available = True
                    avg_daily_price = Decimal("0.00")

                    for day_idx in range(stay_days):
                        target_d = check_in + timedelta(days=day_idx)
                        alloc = allocations_by_date.get(target_d)
                        if not alloc or (alloc.total_allocated - alloc.booked_count) < 1:
                            room_available = False
                            break
                        daily_price = rt.base_price_per_night * alloc.rate_multiplier
                        avg_daily_price += daily_price

                    if room_available:
                        effective_price = avg_daily_price / Decimal(stay_days)
                        available_room_prices.append(effective_price)
                else:
                    # No dates specified -> use base price
                    available_room_prices.append(rt.base_price_per_night)

            if available_room_prices:
                min_price = min(available_room_prices)
            else:
                is_available = False
                min_price = min(rt.base_price_per_night for rt in active_room_types)

            # Price filters
            if params.min_price is not None and min_price < params.min_price:
                continue
            if params.max_price is not None and min_price > params.max_price:
                continue

            cards.append(
                HotelCardResponse(
                    id=prop.id,
                    property_type=prop.property_type,
                    name=prop.name,
                    slug=prop.slug,
                    city=prop.city,
                    address=prop.address,
                    latitude=prop.latitude,
                    longitude=prop.longitude,
                    star_rating=prop.star_rating,
                    review_score=prop.review_score,
                    review_count=prop.review_count,
                    cover_image_url=prop.cover_image_url,
                    amenities=prop.amenities,
                    min_price_per_night=min_price,
                    is_available=is_available,
                )
            )

        # Sorting
        if params.sort_by == "price_asc":
            cards.sort(key=lambda x: x.min_price_per_night)
        elif params.sort_by == "price_desc":
            cards.sort(key=lambda x: x.min_price_per_night, reverse=True)
        elif params.sort_by == "rating_desc":
            cards.sort(key=lambda x: (x.star_rating, x.review_score), reverse=True)

        return cards

    @staticmethod
    async def get_hotel_detail(
        db: AsyncSession, hotel_id: uuid.UUID, check_in: Optional[date] = None, check_out: Optional[date] = None
    ) -> PropertyDetailResponse:
        stmt = (
            select(Property)
            .where(
                Property.id == hotel_id,
                Property.property_type == PropertyType.HOTEL,
                Property.is_published == True,
            )
            .options(
                selectinload(Property.room_types).selectinload(RoomType.allocations)
            )
        )
        result = await db.execute(stmt)
        prop = result.scalar_one_or_none()

        if not prop:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hotel not found.")

        room_types_resp: List[RoomTypeResponse] = []

        for rt in prop.room_types:
            if not rt.is_active:
                continue

            available_rooms = None
            current_price = rt.base_price_per_night

            if check_in and check_out:
                stay_days = (check_out - check_in).days
                if stay_days <= 0:
                    stay_days = 1

                allocations_by_date = {
                    alloc.allocation_date: alloc for alloc in rt.allocations if not alloc.is_closed
                }
                
                min_avail = 9999
                total_cost = Decimal("0.00")
                is_fully_available = True

                for day_idx in range(stay_days):
                    target_d = check_in + timedelta(days=day_idx)
                    alloc = allocations_by_date.get(target_d)
                    if not alloc:
                        is_fully_available = False
                        min_avail = 0
                        break
                    free_count = alloc.total_allocated - alloc.booked_count
                    if free_count < min_avail:
                        min_avail = free_count
                    total_cost += rt.base_price_per_night * alloc.rate_multiplier

                if is_fully_available and min_avail > 0:
                    available_rooms = min_avail
                    current_price = total_cost / Decimal(stay_days)
                else:
                    available_rooms = 0

            room_types_resp.append(
                RoomTypeResponse(
                    id=rt.id,
                    property_id=rt.property_id,
                    name=rt.name,
                    description=rt.description,
                    max_occupancy=rt.max_occupancy,
                    bed_configuration=rt.bed_configuration,
                    base_price_per_night=rt.base_price_per_night,
                    amenities=rt.amenities,
                    images=rt.images,
                    is_active=rt.is_active,
                    available_rooms=available_rooms,
                    current_price_per_night=current_price,
                    created_at=rt.created_at,
                )
            )

        return PropertyDetailResponse(
            id=prop.id,
            vendor_id=prop.vendor_id,
            property_type=prop.property_type,
            name=prop.name,
            slug=prop.slug,
            description=prop.description,
            tagline=prop.tagline,
            address=prop.address,
            city=prop.city,
            state=prop.state,
            country=prop.country,
            postal_code=prop.postal_code,
            latitude=prop.latitude,
            longitude=prop.longitude,
            star_rating=prop.star_rating,
            review_score=prop.review_score,
            review_count=prop.review_count,
            cover_image_url=prop.cover_image_url,
            gallery_images=prop.gallery_images,
            amenities=prop.amenities,
            check_in_time=prop.check_in_time,
            check_out_time=prop.check_out_time,
            cancellation_policy=prop.cancellation_policy,
            is_published=prop.is_published,
            room_types=room_types_resp,
            associated_guides=[],
            created_at=prop.created_at,
        )
