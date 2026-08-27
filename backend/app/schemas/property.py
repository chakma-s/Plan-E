import uuid
from datetime import date, time, datetime
from typing import List, Optional, Union
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field

from app.models.property import PropertyType
from app.schemas.room import RoomTypeResponse
from app.schemas.guide import LocalGuideSummary


class PropertyBase(BaseModel):
    name: str
    description: str
    tagline: Optional[str] = None
    address: str
    city: str
    state: Optional[str] = None
    country: str
    postal_code: Optional[str] = None
    latitude: Decimal
    longitude: Decimal
    star_rating: Decimal = Decimal("4.0")
    cover_image_url: str
    gallery_images: List[str] = Field(default_factory=list)
    amenities: List[str] = Field(default_factory=list)
    check_in_time: time = time(15, 0, 0)
    check_out_time: time = time(11, 0, 0)
    cancellation_policy: str = "Free cancellation up to 48 hours before check-in."
    is_published: bool = True



class PropertyUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    tagline: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None
    star_rating: Optional[Decimal] = None
    cover_image_url: Optional[str] = None
    gallery_images: Optional[List[str]] = None
    amenities: Optional[List[str]] = None
    check_in_time: Optional[time] = None
    check_out_time: Optional[time] = None
    cancellation_policy: Optional[str] = None
    is_published: Optional[bool] = None

class PropertyCreate(PropertyBase):
    property_type: PropertyType
    vendor_id: uuid.UUID


# -----------------------------------------------------------------------------
# 1. HOTEL-SPECIFIC SCHEMAS (Transactional & Velocity Focused)
# -----------------------------------------------------------------------------
class HotelSearchParams(BaseModel):
    city: Optional[str] = None
    check_in: Optional[date] = None
    check_out: Optional[date] = None
    guests: int = 1
    min_lat: Optional[Decimal] = None
    max_lat: Optional[Decimal] = None
    min_lon: Optional[Decimal] = None
    max_lon: Optional[Decimal] = None
    min_price: Optional[Decimal] = None
    max_price: Optional[Decimal] = None
    min_rating: Optional[Decimal] = None
    sort_by: str = "recommended"  # price_asc, price_desc, rating_desc, distance


class HotelCardResponse(BaseModel):
    """Lean response tailored for rapid hotel search results & map markers."""
    id: uuid.UUID
    property_type: PropertyType = PropertyType.HOTEL
    name: str
    slug: str
    city: str
    address: str
    latitude: Decimal
    longitude: Decimal
    star_rating: Decimal
    review_score: Decimal
    review_count: int
    cover_image_url: str
    amenities: List[str]
    min_price_per_night: Decimal
    is_available: bool = True

    model_config = ConfigDict(from_attributes=True)


# -----------------------------------------------------------------------------
# 2. RESORT-SPECIFIC SCHEMAS (Immersive Vacation + Local Guide Bundles)
# -----------------------------------------------------------------------------
class ResortSearchParams(BaseModel):
    destination: Optional[str] = None
    check_in: Optional[date] = None
    check_out: Optional[date] = None
    guests: int = 1
    amenities: Optional[List[str]] = None
    min_lat: Optional[Decimal] = None
    max_lat: Optional[Decimal] = None
    min_lon: Optional[Decimal] = None
    max_lon: Optional[Decimal] = None
    with_guides_only: bool = False
    sort_by: str = "featured"  # featured, price_asc, rating_desc


class ResortCardResponse(BaseModel):
    """Immersive response featuring luxury imagery, amenities, and available guide roster."""
    id: uuid.UUID
    property_type: PropertyType = PropertyType.RESORT
    name: str
    slug: str
    tagline: Optional[str] = None
    city: str
    country: str
    latitude: Decimal
    longitude: Decimal
    star_rating: Decimal
    review_score: Decimal
    review_count: int
    cover_image_url: str
    gallery_images: List[str]
    amenities: List[str]
    starting_price_per_night: Decimal
    # Local Guide Bundling feature preview
    available_guides_count: int = 0
    featured_guides: List[LocalGuideSummary] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


# -----------------------------------------------------------------------------
# 3. DETAILED PROPERTY SCHEMA
# -----------------------------------------------------------------------------
class PropertyDetailResponse(BaseModel):
    id: uuid.UUID
    vendor_id: uuid.UUID
    property_type: PropertyType
    name: str
    slug: str
    description: str
    tagline: Optional[str] = None
    address: str
    city: str
    state: Optional[str] = None
    country: str
    postal_code: Optional[str] = None
    latitude: Decimal
    longitude: Decimal
    star_rating: Decimal
    review_score: Decimal
    review_count: int
    cover_image_url: str
    gallery_images: List[str]
    amenities: List[str]
    check_in_time: time
    check_out_time: time
    cancellation_policy: str
    is_published: bool
    room_types: List[RoomTypeResponse] = Field(default_factory=list)
    # Populated only for Resorts
    associated_guides: List[LocalGuideSummary] = Field(default_factory=list)
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
