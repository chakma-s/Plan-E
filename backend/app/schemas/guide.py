import uuid
from datetime import date, datetime
from typing import List, Optional
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field


class LocalGuideBase(BaseModel):
    full_name: str
    headline: str
    bio: str
    profile_photo_url: str
    languages: List[str] = Field(default_factory=lambda: ["English"])
    years_of_experience: int = 1
    license_number: Optional[str] = None
    hourly_rate: Decimal = Decimal("35.00")
    daily_rate: Decimal = Decimal("200.00")
    specialties: List[str] = Field(default_factory=list)
    is_active: bool = True


class LocalGuideCreate(LocalGuideBase):
    user_id: Optional[uuid.UUID] = None
    vendor_id: Optional[uuid.UUID] = None


class LocalGuideSummary(BaseModel):
    """Concise representation for resort cards and bundle selectors."""
    id: uuid.UUID
    full_name: str
    headline: str
    profile_photo_url: str
    languages: List[str]
    daily_rate: Decimal
    rating: Decimal
    review_count: int
    specialties: List[str]
    is_verified: bool

    model_config = ConfigDict(from_attributes=True)


class GuideAvailabilityResponse(BaseModel):
    id: uuid.UUID
    guide_id: uuid.UUID
    availability_date: date
    is_available: bool
    is_booked: bool

    model_config = ConfigDict(from_attributes=True)


class LocalGuideDetail(LocalGuideSummary):
    """Full detail view for Local Guide modal / sheet."""
    bio: str
    years_of_experience: int
    license_number: Optional[str] = None
    hourly_rate: Decimal
    is_active: bool
    availabilities: List[GuideAvailabilityResponse] = Field(default_factory=list)
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
