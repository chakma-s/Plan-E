import random
import string
import uuid
from datetime import date, timedelta, datetime
from typing import List, Optional
from decimal import Decimal, ROUND_HALF_UP
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.core.config import settings
from app.models.booking import (
    Reservation,
    RoomBookingItem,
    GuideBookingItem,
    BookingType,
    BookingStatus,
    PaymentStatus,
)
from app.models.property import Property, PropertyType
from app.models.room import RoomType, RoomAllocation
from app.models.guide import LocalGuide, GuideAvailability
from app.models.user import User
from app.schemas.booking import (
    ReservationCreateRequest,
    PriceQuoteRequest,
    PriceQuoteResponse,
    ReservationResponse,
    RoomBookingItemResponse,
    GuideBookingItemResponse,
)


def generate_reservation_code() -> str:
    """Generate a clean, professional booking reference code: e.g. OTA-2026-X8B2."""
    chars = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
    year = datetime.now().year
    return f"OTA-{year}-{chars}"


class BookingService:
    """
    Core Transactional Booking Engine.
    Enforces atomic room inventory allocation and exclusive guide calendar locks.
    """

    @classmethod
    async def calculate_price_quote(
        cls, db: AsyncSession, quote_req: PriceQuoteRequest
    ) -> PriceQuoteResponse:
        stay_nights = (quote_req.check_out_date - quote_req.check_in_date).days
        if stay_nights <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Check-out date must be after check-in date."
            )

        room_subtotal = Decimal("0.00")
        guide_subtotal = Decimal("0.00")
        is_available = True
        unavailability_reason = None

        # 1. Calculate Room Charges & Verify Allocation Availability
        for room_item in quote_req.room_items:
            stmt = (
                select(RoomType)
                .where(RoomType.id == room_item.room_type_id, RoomType.is_active == True)
                .options(selectinload(RoomType.allocations))
            )
            result = await db.execute(stmt)
            room_type = result.scalar_one_or_none()

            if not room_type:
                return PriceQuoteResponse(
                    total_nights=stay_nights,
                    room_subtotal=Decimal("0.00"),
                    guide_subtotal=Decimal("0.00"),
                    platform_fee=Decimal("0.00"),
                    tax_amount=Decimal("0.00"),
                    total_amount=Decimal("0.00"),
                    is_available=False,
                    unavailability_reason=f"Room type {room_item.room_type_id} does not exist or is inactive.",
                )

            alloc_map = {
                alloc.allocation_date: alloc for alloc in room_type.allocations if not alloc.is_closed
            }

            item_room_cost = Decimal("0.00")
            for day_idx in range(stay_nights):
                target_d = quote_req.check_in_date + timedelta(days=day_idx)
                alloc = alloc_map.get(target_d)

                if not alloc:
                    is_available = False
                    unavailability_reason = f"No room allocation found for {room_type.name} on {target_d}."
                    break

                free_rooms = alloc.total_allocated - alloc.booked_count
                if free_rooms < room_item.rooms_count:
                    is_available = False
                    unavailability_reason = (
                        f"Only {free_rooms} rooms available for {room_type.name} on {target_d}, "
                        f"requested {room_item.rooms_count}."
                    )
                    break

                daily_cost = (
                    room_type.base_price_per_night
                    * alloc.rate_multiplier
                    * Decimal(room_item.rooms_count)
                )
                item_room_cost += daily_cost

            room_subtotal += item_room_cost

        # 2. Calculate Guide Charges & Verify Guide Availability (if bundled)
        if quote_req.guide_bundle and is_available:
            guide_req = quote_req.guide_bundle
            stmt = (
                select(LocalGuide)
                .where(LocalGuide.id == guide_req.guide_id, LocalGuide.is_active == True)
                .options(selectinload(LocalGuide.availabilities))
            )
            result = await db.execute(stmt)
            guide = result.scalar_one_or_none()

            if not guide:
                is_available = False
                unavailability_reason = "Selected local guide not found or inactive."
            else:
                guide_avail_map = {av.availability_date: av for av in guide.availabilities}
                for day_idx in range(guide_req.duration_days):
                    target_d = guide_req.service_date + timedelta(days=day_idx)
                    av = guide_avail_map.get(target_d)
                    if not av or not av.is_available or av.is_booked:
                        is_available = False
                        unavailability_reason = f"Local guide {guide.full_name} is unavailable on {target_d}."
                        break

                guide_subtotal = guide.daily_rate * Decimal(guide_req.duration_days)

        # 3. Calculate Platform Fees and Taxes
        platform_fee = (
            (room_subtotal + guide_subtotal) * Decimal(str(settings.PLATFORM_FEE_PERCENTAGE / 100))
        ).quantize(Decimal(".01"), rounding=ROUND_HALF_UP)

        tax_amount = (
            (room_subtotal + guide_subtotal) * Decimal(str(settings.DEFAULT_TAX_PERCENTAGE / 100))
        ).quantize(Decimal(".01"), rounding=ROUND_HALF_UP)

        total_amount = room_subtotal + guide_subtotal + platform_fee + tax_amount

        return PriceQuoteResponse(
            total_nights=stay_nights,
            room_subtotal=room_subtotal.quantize(Decimal(".01")),
            guide_subtotal=guide_subtotal.quantize(Decimal(".01")),
            platform_fee=platform_fee,
            tax_amount=tax_amount,
            total_amount=total_amount.quantize(Decimal(".01")),
            currency="USD",
            is_available=is_available,
            unavailability_reason=unavailability_reason,
        )

    @classmethod
    async def create_reservation(
        cls, db: AsyncSession, user_id: uuid.UUID, req: ReservationCreateRequest
    ) -> ReservationResponse:
        # Check Idempotency Key
        if req.idempotency_key:
            stmt = select(Reservation).where(Reservation.idempotency_key == req.idempotency_key)
            result = await db.execute(stmt)
            existing_res = result.scalar_one_or_none()
            if existing_res:
                return await cls.get_reservation_by_id(db, existing_res.id)

        stay_nights = (req.check_out_date - req.check_in_date).days
        if stay_nights <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Check-out date must be strictly after check-in date."
            )

        # Retrieve Property
        stmt = select(Property).where(Property.id == req.property_id, Property.is_published == True)
        result = await db.execute(stmt)
        property_obj = result.scalar_one_or_none()
        if not property_obj:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found.")

        # Determine Booking Type
        if property_obj.property_type == PropertyType.HOTEL:
            booking_type = BookingType.HOTEL_ONLY
            if req.guide_bundle:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Local guide bundling is exclusively available for Resort reservations."
                )
        else:
            booking_type = BookingType.RESORT_WITH_GUIDE if req.guide_bundle else BookingType.RESORT_ONLY

        room_items_to_create: List[RoomBookingItem] = []
        room_subtotal = Decimal("0.00")

        # ---------------------------------------------------------------------
        # 1. Pessimistic Row Lock & Inventory Allocation Deduction
        # ---------------------------------------------------------------------
        for room_item in req.room_items:
            stmt = select(RoomType).where(RoomType.id == room_item.room_type_id)
            result = await db.execute(stmt)
            room_type = result.scalar_one_or_none()
            if not room_type or room_type.property_id != req.property_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid room type {room_item.room_type_id} for this property."
                )

            item_total = Decimal("0.00")

            for day_idx in range(stay_nights):
                target_d = req.check_in_date + timedelta(days=day_idx)

                # Lock allocation row for update
                alloc_stmt = (
                    select(RoomAllocation)
                    .where(
                        RoomAllocation.room_type_id == room_type.id,
                        RoomAllocation.allocation_date == target_d,
                        RoomAllocation.is_closed == False,
                    )
                    .with_for_update()
                )
                alloc_result = await db.execute(alloc_stmt)
                alloc = alloc_result.scalar_one_or_none()

                if not alloc:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=f"No room allocation open for {room_type.name} on {target_d}."
                    )

                if (alloc.total_allocated - alloc.booked_count) < room_item.rooms_count:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=f"Overbooking prevented: Not enough {room_type.name} rooms available on {target_d}."
                    )

                # Atomically decrement available allocation
                alloc.booked_count += room_item.rooms_count

                daily_rate = room_type.base_price_per_night * alloc.rate_multiplier
                item_total += daily_rate * Decimal(room_item.rooms_count)

            price_per_night_avg = item_total / Decimal(stay_nights * room_item.rooms_count)
            room_subtotal += item_total

            room_items_to_create.append(
                RoomBookingItem(
                    room_type_id=room_type.id,
                    rooms_count=room_item.rooms_count,
                    price_per_night=price_per_night_avg.quantize(Decimal(".01")),
                    total_price=item_total.quantize(Decimal(".01")),
                )
            )

        # ---------------------------------------------------------------------
        # 2. Guide Bundling: Lock Guide Calendar & Assign Item
        # ---------------------------------------------------------------------
        guide_item_to_create: Optional[GuideBookingItem] = None
        guide_subtotal = Decimal("0.00")

        if req.guide_bundle:
            guide_req = req.guide_bundle
            stmt = select(LocalGuide).where(LocalGuide.id == guide_req.guide_id, LocalGuide.is_active == True)
            result = await db.execute(stmt)
            guide = result.scalar_one_or_none()

            if not guide:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Local Guide not found.")

            for day_idx in range(guide_req.duration_days):
                target_d = guide_req.service_date + timedelta(days=day_idx)

                # Lock guide availability row for update
                g_stmt = (
                    select(GuideAvailability)
                    .where(
                        GuideAvailability.guide_id == guide.id,
                        GuideAvailability.availability_date == target_d,
                    )
                    .with_for_update()
                )
                g_res = await db.execute(g_stmt)
                guide_avail = g_res.scalar_one_or_none()

                if not guide_avail or not guide_avail.is_available or guide_avail.is_booked:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=f"Guide {guide.full_name} is already booked or unavailable on {target_d}."
                    )

                # Mark guide as booked
                guide_avail.is_booked = True

            guide_fee = guide.daily_rate * Decimal(guide_req.duration_days)
            guide_subtotal = guide_fee

            guide_item_to_create = GuideBookingItem(
                guide_id=guide.id,
                service_date=guide_req.service_date,
                duration_days=guide_req.duration_days,
                daily_rate=guide.daily_rate,
                total_guide_fee=guide_fee.quantize(Decimal(".01")),
                special_requirements=guide_req.special_requirements,
            )

        # ---------------------------------------------------------------------
        # 3. Financial Calculation & Master Reservation Creation
        # ---------------------------------------------------------------------
        platform_fee = (
            (room_subtotal + guide_subtotal) * Decimal(str(settings.PLATFORM_FEE_PERCENTAGE / 100))
        ).quantize(Decimal(".01"), rounding=ROUND_HALF_UP)

        tax_amount = (
            (room_subtotal + guide_subtotal) * Decimal(str(settings.DEFAULT_TAX_PERCENTAGE / 100))
        ).quantize(Decimal(".01"), rounding=ROUND_HALF_UP)

        total_amount = room_subtotal + guide_subtotal + platform_fee + tax_amount

        reservation_code = generate_reservation_code()

        reservation = Reservation(
            reservation_code=reservation_code,
            user_id=user_id,
            property_id=property_obj.id,
            booking_type=booking_type,
            status=BookingStatus.CONFIRMED,
            payment_status=PaymentStatus.PAID,
            idempotency_key=req.idempotency_key,
            check_in_date=req.check_in_date,
            check_out_date=req.check_out_date,
            total_nights=stay_nights,
            guest_count=req.guest_count,
            room_subtotal=room_subtotal.quantize(Decimal(".01")),
            guide_subtotal=guide_subtotal.quantize(Decimal(".01")),
            platform_fee=platform_fee,
            tax_amount=tax_amount,
            total_amount=total_amount.quantize(Decimal(".01")),
            currency="USD",
            special_requests=req.special_requests,
        )
        db.add(reservation)
        await db.flush()

        for r_item in room_items_to_create:
            r_item.reservation_id = reservation.id
            db.add(r_item)

        if guide_item_to_create:
            guide_item_to_create.reservation_id = reservation.id
            db.add(guide_item_to_create)

        await db.commit()
        return await cls.get_reservation_by_id(db, reservation.id)


    @classmethod
    async def cancel_reservation(cls, db: AsyncSession, current_user: User, reservation_id: uuid.UUID) -> Reservation:
        # Load reservation with relations
        stmt = (
            select(Reservation)
            .where(Reservation.id == reservation_id)
            .options(
                selectinload(Reservation.room_items),
                selectinload(Reservation.guide_items),
            )
        )
        result = await db.execute(stmt)
        res = result.scalar_one_or_none()
        
        if not res:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found.")
            
        if res.user_id != current_user.id and current_user.role.value != "ADMIN":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized.")
            
        if res.status == BookingStatus.CANCELLED:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reservation already cancelled.")
            
        # 1. Restore room allocations
        for room_item in res.room_items:
            for day_idx in range(res.total_nights):
                target_d = res.check_in_date + timedelta(days=day_idx)
                alloc_stmt = (
                    select(RoomAllocation)
                    .where(
                        RoomAllocation.room_type_id == room_item.room_type_id,
                        RoomAllocation.allocation_date == target_d,
                    )
                    .with_for_update()
                )
                alloc_res = await db.execute(alloc_stmt)
                alloc = alloc_res.scalar_one_or_none()
                if alloc:
                    alloc.booked_count = max(0, alloc.booked_count - room_item.rooms_count)
                    
        # 2. Restore guide availability
        for guide_item in res.guide_items:
            for day_idx in range(guide_item.duration_days):
                target_d = guide_item.service_date + timedelta(days=day_idx)
                g_stmt = (
                    select(GuideAvailability)
                    .where(
                        GuideAvailability.guide_id == guide_item.guide_id,
                        GuideAvailability.availability_date == target_d,
                    )
                    .with_for_update()
                )
                g_res = await db.execute(g_stmt)
                guide_avail = g_res.scalar_one_or_none()
                if guide_avail:
                    guide_avail.is_booked = False
                    
        res.status = BookingStatus.CANCELLED
        res.payment_status = PaymentStatus.REFUNDED
        await db.commit()
        return res

    @classmethod
    async def get_reservation_by_id(cls, db: AsyncSession, reservation_id: uuid.UUID) -> ReservationResponse:
        stmt = (
            select(Reservation)
            .where(Reservation.id == reservation_id)
            .options(
                selectinload(Reservation.property),
                selectinload(Reservation.room_items).selectinload(RoomBookingItem.room_type),
                selectinload(Reservation.guide_items).selectinload(GuideBookingItem.guide),
            )
        )
        result = await db.execute(stmt)
        res = result.scalar_one_or_none()
        if not res:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found.")

        room_items_resp = [
            RoomBookingItemResponse(
                id=item.id,
                room_type_id=item.room_type_id,
                room_name=item.room_type.name,
                rooms_count=item.rooms_count,
                price_per_night=item.price_per_night,
                total_price=item.total_price,
            )
            for item in res.room_items
        ]

        guide_item_resp = None
        if res.guide_items:
            g_item = res.guide_items[0]
            guide_item_resp = GuideBookingItemResponse(
                id=g_item.id,
                guide_id=g_item.guide_id,
                guide_name=g_item.guide.full_name,
                guide_photo_url=g_item.guide.profile_photo_url,
                service_date=g_item.service_date,
                duration_days=g_item.duration_days,
                daily_rate=g_item.daily_rate,
                total_guide_fee=g_item.total_guide_fee,
                special_requirements=g_item.special_requirements,
            )

        return ReservationResponse(
            id=res.id,
            reservation_code=res.reservation_code,
            user_id=res.user_id,
            property_id=res.property_id,
            property_name=res.property.name,
            property_type=res.property.property_type.value,
            booking_type=res.booking_type,
            status=res.status,
            payment_status=res.payment_status,
            check_in_date=res.check_in_date,
            check_out_date=res.check_out_date,
            total_nights=res.total_nights,
            guest_count=res.guest_count,
            room_subtotal=res.room_subtotal,
            guide_subtotal=res.guide_subtotal,
            platform_fee=res.platform_fee,
            tax_amount=res.tax_amount,
            total_amount=res.total_amount,
            currency=res.currency,
            special_requests=res.special_requests,
            room_items=room_items_resp,
            guide_item=guide_item_resp,
            created_at=res.created_at,
        )

    @classmethod
    async def get_user_reservations(cls, db: AsyncSession, user_id: uuid.UUID) -> List[ReservationResponse]:
        stmt = (
            select(Reservation.id)
            .where(Reservation.user_id == user_id)
            .order_by(Reservation.created_at.desc())
        )
        result = await db.execute(stmt)
        res_ids = result.scalars().all()
        return [await cls.get_reservation_by_id(db, res_id) for res_id in res_ids]
