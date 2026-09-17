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


class PaginationParams(BaseModel):
    """Standardized query pagination parameters."""
    page: int = Field(default=1, ge=1, description="Page number")
    page_size: int = Field(default=20, ge=1, le=100, description="Items per page (max 100)")

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.page_size



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
