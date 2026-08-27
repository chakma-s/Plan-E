from typing import Generic, TypeVar, List, Optional
from pydantic import BaseModel, ConfigDict, Field
from decimal import Decimal

T = TypeVar("T")


class APIResponse(BaseModel, Generic[T]):
    """Standard unified API response wrapper."""
    success: bool = True
    message: str = "Success"
    data: Optional[T] = None


class PaginatedResponse(BaseModel, Generic[T]):
    """Paginated list response wrapper."""
    total: int
    page: int
    page_size: int
    total_pages: int
    items: List[T]


class GeoBoundingBox(BaseModel):
    """Mapbox viewport bounding box coordinates."""
    min_lat: Decimal = Field(..., description="South latitude bound")
    max_lat: Decimal = Field(..., description="North latitude bound")
    min_lon: Decimal = Field(..., description="West longitude bound")
    max_lon: Decimal = Field(..., description="East longitude bound")


class GeoLocation(BaseModel):
    """Latitude/Longitude point."""
    latitude: Decimal
    longitude: Decimal
