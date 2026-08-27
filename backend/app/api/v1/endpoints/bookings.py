import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.booking import (
    PriceQuoteRequest,
    PriceQuoteResponse,
    ReservationCreateRequest,
    ReservationResponse,
)
from app.schemas.common import APIResponse
from app.services.booking_service import BookingService

router = APIRouter()


@router.post("/quote", response_model=APIResponse[PriceQuoteResponse])
async def get_price_quote(
    quote_req: PriceQuoteRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Real-time price calculation and allocation availability quote.
    Evaluates stay duration, room allocation rates, and optional Local Guide bundle fees.
    """
    quote = await BookingService.calculate_price_quote(db, quote_req)
    return APIResponse(data=quote)


@router.post("", response_model=APIResponse[ReservationResponse], status_code=status.HTTP_201_CREATED)
async def create_reservation(
    req: ReservationCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Execute an atomic, ACID-compliant reservation transaction.
    - Locks room allocation rows (`SELECT FOR UPDATE`) and decrements available inventory.
    - Locks and reserves the certified Local Guide's calendar if bundled.
    - Itemizes room charges, guide fees, taxes, and platform service fees.
    """
    reservation = await BookingService.create_reservation(db, current_user.id, req)
    return APIResponse(
        message="Reservation confirmed successfully.",
        data=reservation,
    )


@router.get("/my-reservations", response_model=APIResponse[List[ReservationResponse]])
async def get_my_reservations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieve all current and past reservations for the authenticated traveler.
    """
    reservations = await BookingService.get_user_reservations(db, current_user.id)
    return APIResponse(data=reservations)


@router.get("/{reservation_id}", response_model=APIResponse[ReservationResponse])
async def get_reservation_by_id(
    reservation_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieve itemized details and receipt for a specific reservation.
    """
    reservation = await BookingService.get_reservation_by_id(db, reservation_id)
    # Ensure user owns reservation or is admin
    if reservation.user_id != current_user.id and current_user.role.value != "ADMIN":
        from fastapi import HTTPException
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized access to reservation.")
    return APIResponse(data=reservation)


@router.post("/{reservation_id}/cancel", response_model=APIResponse[dict])
async def cancel_reservation(
    reservation_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # This calls the service which we will add next
    res = await BookingService.cancel_reservation(db, current_user, reservation_id)
    return APIResponse(message="Reservation cancelled successfully.", data={"id": res.id})
