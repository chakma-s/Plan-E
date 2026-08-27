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
from app.models.guide import LocalGuide, ResortGuideAssociation, GuideAvailability
from app.schemas.property import (
    ResortSearchParams,
    ResortCardResponse,
    PropertyDetailResponse,
)
from app.schemas.guide import LocalGuideSummary
from app.schemas.room import RoomTypeResponse


class ResortService:
    """
    Dedicated Resort Pipeline.
    Optimized for immersive vacation planning, rich media presentation, and Local Guide Bundling.
    """

    @staticmethod
    async def search_resorts(db: AsyncSession, params: ResortSearchParams) -> List[ResortCardResponse]:
        query = select(Property).where(
            Property.property_type == PropertyType.RESORT,
            Property.is_published == True,
        ).options(
            selectinload(Property.room_types).selectinload(RoomType.allocations),
            selectinload(Property.guide_associations)
            .selectinload(ResortGuideAssociation.guide)
            .selectinload(LocalGuide.availabilities),
        )

        # 1. Destination / Keyword Filter
        if params.destination:
            dest_filter = f"%{params.destination.strip().lower()}%"
            query = query.where(
                or_(
                    func.lower(Property.city).like(dest_filter),
                    func.lower(Property.state).like(dest_filter),
                    func.lower(Property.country).like(dest_filter),
                    func.lower(Property.name).like(dest_filter),
                    func.lower(Property.description).like(dest_filter),
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

        result = await db.execute(query)
        properties = result.scalars().all()

        check_in = params.check_in
        check_out = params.check_out

        cards: List[ResortCardResponse] = []

        for prop in properties:
            # 3. Amenity Filtering
            if params.amenities:
                prop_amenities_lower = [a.lower() for a in prop.amenities]
                if not all(req.lower() in prop_amenities_lower for req in params.amenities):
                    continue

            # 4. Room Types & Starting Price
            active_rooms = [rt for rt in prop.room_types if rt.is_active and rt.max_occupancy >= params.guests]
            if not active_rooms:
                continue

            starting_price = min(rt.base_price_per_night for rt in active_rooms)

            # 5. Local Guide Bundling Roster & Availability
            associated_guides: List[LocalGuide] = [
                assoc.guide for assoc in prop.guide_associations if assoc.guide.is_active
            ]

            available_guides: List[LocalGuideSummary] = []
            for guide in associated_guides:
                is_guide_free = True
                if check_in and check_out:
                    stay_days = (check_out - check_in).days
                    guide_avail_map = {
                        av.availability_date: av for av in guide.availabilities
                    }
                    for day_idx in range(stay_days):
                        target_d = check_in + timedelta(days=day_idx)
                        av = guide_avail_map.get(target_d)
                        if not av or not av.is_available or av.is_booked:
                            is_guide_free = False
                            break

                if is_guide_free:
                    available_guides.append(
                        LocalGuideSummary(
                            id=guide.id,
                            full_name=guide.full_name,
                            headline=guide.headline,
                            profile_photo_url=guide.profile_photo_url,
                            languages=guide.languages,
                            daily_rate=guide.daily_rate,
                            rating=guide.rating,
                            review_count=guide.review_count,
                            specialties=guide.specialties,
                            is_verified=guide.is_verified,
                        )
                    )

            if params.with_guides_only and len(available_guides) == 0:
                continue

            cards.append(
                ResortCardResponse(
                    id=prop.id,
                    property_type=prop.property_type,
                    name=prop.name,
                    slug=prop.slug,
                    tagline=prop.tagline,
                    city=prop.city,
                    country=prop.country,
                    latitude=prop.latitude,
                    longitude=prop.longitude,
                    star_rating=prop.star_rating,
                    review_score=prop.review_score,
                    review_count=prop.review_count,
                    cover_image_url=prop.cover_image_url,
                    gallery_images=prop.gallery_images,
                    amenities=prop.amenities,
                    starting_price_per_night=starting_price,
                    available_guides_count=len(available_guides),
                    featured_guides=available_guides[:3],
                )
            )

        # Sorting
        if params.sort_by == "price_asc":
            cards.sort(key=lambda x: x.starting_price_per_night)
        elif params.sort_by == "rating_desc":
            cards.sort(key=lambda x: (x.star_rating, x.review_score), reverse=True)

        return cards

    @staticmethod
    async def get_resort_detail(
        db: AsyncSession, resort_id: uuid.UUID, check_in: Optional[date] = None, check_out: Optional[date] = None
    ) -> PropertyDetailResponse:
        stmt = (
            select(Property)
            .where(
                Property.id == resort_id,
                Property.property_type == PropertyType.RESORT,
                Property.is_published == True,
            )
            .options(
                selectinload(Property.room_types).selectinload(RoomType.allocations),
                selectinload(Property.guide_associations)
                .selectinload(ResortGuideAssociation.guide)
                .selectinload(LocalGuide.availabilities),
            )
        )
        result = await db.execute(stmt)
        prop = result.scalar_one_or_none()

        if not prop:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resort not found.")

        # Process Room Types
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

        # Process Associated Local Guides
        guides_summary: List[LocalGuideSummary] = []
        for assoc in prop.guide_associations:
            guide = assoc.guide
            if not guide.is_active:
                continue
            guides_summary.append(
                LocalGuideSummary(
                    id=guide.id,
                    full_name=guide.full_name,
                    headline=guide.headline,
                    profile_photo_url=guide.profile_photo_url,
                    languages=guide.languages,
                    daily_rate=guide.daily_rate,
                    rating=guide.rating,
                    review_count=guide.review_count,
                    specialties=guide.specialties,
                    is_verified=guide.is_verified,
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
            associated_guides=guides_summary,
            created_at=prop.created_at,
        )
