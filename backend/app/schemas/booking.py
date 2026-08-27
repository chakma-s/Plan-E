import uuid
from datetime import date, datetime
from typing import List, Optional
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field

from app.models.booking import BookingType, BookingStatus, PaymentStatus
from app.schemas.guide import LocalGuideSummary


class RoomBookingItemRequest(BaseModel):
    room_type_id: uuid.UUID
    rooms_count: int = Field(default=1, ge=1)


class GuideBookingItemRequest(BaseModel):
    """Local Guide bundling item request."""
    guide_id: uuid.UUID
    service_date: date
    duration_days: int = Field(default=1, ge=1)
    special_requirements: Optional[str] = None


class ReservationCreateRequest(BaseModel):
    """
    Composite reservation request supporting:
    - Pure Hotel bookings
    - Pure Resort bookings
    - Bundled Resort + Local Guide bookings
    """
    property_id: uuid.UUID
    check_in_date: date
    check_out_date: date
    guest_count: int = Field(default=1, ge=1)
    room_items: List[RoomBookingItemRequest] = Field(..., min_length=1)
    guide_bundle: Optional[GuideBookingItemRequest] = None
    special_requests: Optional[str] = None
    idempotency_key: Optional[str] = None


class PriceQuoteRequest(BaseModel):
    property_id: uuid.UUID
    check_in_date: date
    check_out_date: date
    room_items: List[RoomBookingItemRequest]
    guide_bundle: Optional[GuideBookingItemRequest] = None


class PriceQuoteResponse(BaseModel):
    total_nights: int
    room_subtotal: Decimal
    guide_subtotal: Decimal
    platform_fee: Decimal
    tax_amount: Decimal
    total_amount: Decimal
    currency: str = "USD"
    is_available: bool = True
    unavailability_reason: Optional[str] = None


class RoomBookingItemResponse(BaseModel):
    id: uuid.UUID
    room_type_id: uuid.UUID
    room_name: str
    rooms_count: int
    price_per_night: Decimal
    total_price: Decimal

    model_config = ConfigDict(from_attributes=True)


class GuideBookingItemResponse(BaseModel):
    id: uuid.UUID
    guide_id: uuid.UUID
    guide_name: str
    guide_photo_url: str
    service_date: date
    duration_days: int
    daily_rate: Decimal
    total_guide_fee: Decimal
    special_requirements: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ReservationResponse(BaseModel):
    id: uuid.UUID
    reservation_code: str
    user_id: uuid.UUID
    property_id: uuid.UUID
    property_name: str
    property_type: str
    booking_type: BookingType
    status: BookingStatus
    payment_status: PaymentStatus
    check_in_date: date
    check_out_date: date
    total_nights: int
    guest_count: int
    room_subtotal: Decimal
    guide_subtotal: Decimal
    platform_fee: Decimal
    tax_amount: Decimal
    total_amount: Decimal
    currency: str
    special_requests: Optional[str] = None
    room_items: List[RoomBookingItemResponse] = Field(default_factory=list)
    guide_item: Optional[GuideBookingItemResponse] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
