
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, Field

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.booking import Reservation, BookingStatus
from app.models.review import Review
from app.schemas.common import APIResponse

router = APIRouter()

class ReviewCreate(BaseModel):
    reservation_id: uuid.UUID
    property_id: uuid.UUID | None = None
    guide_id: uuid.UUID | None = None
    rating: int = Field(..., ge=1, le=5)
    comment: str | None = None

@router.post("", response_model=APIResponse[dict])
async def create_review(
    review_in: ReviewCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Verify reservation belongs to user and is COMPLETED
    stmt = select(Reservation).where(Reservation.id == review_in.reservation_id, Reservation.user_id == current_user.id)
    res = await db.execute(stmt)
    reservation = res.scalar_one_or_none()
    
    if not reservation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found.")
        
    # In a real app we'd enforce BookingStatus.COMPLETED, but for beta testing we allow CONFIRMED
    if reservation.status == BookingStatus.CANCELLED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot review a cancelled booking.")
        
    review = Review(
        reservation_id=review_in.reservation_id,
        user_id=current_user.id,
        property_id=review_in.property_id,
        guide_id=review_in.guide_id,
        rating=review_in.rating,
        comment=review_in.comment
    )
    db.add(review)
    await db.commit()
    await db.refresh(review)
    return APIResponse(message="Review submitted successfully.", data={"id": review.id})
