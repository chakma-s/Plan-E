import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field
from app.models.review import ReviewTargetType


class ReviewCreate(BaseModel):
    reservation_id: uuid.UUID
    target_type: ReviewTargetType
    property_id: Optional[uuid.UUID] = None
    guide_id: Optional[uuid.UUID] = None
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


class ReviewResponse(BaseModel):
    id: uuid.UUID
    reservation_id: uuid.UUID
    user_id: uuid.UUID
    user_name: str
    target_type: ReviewTargetType
    property_id: Optional[uuid.UUID] = None
    guide_id: Optional[uuid.UUID] = None
    rating: int
    comment: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
