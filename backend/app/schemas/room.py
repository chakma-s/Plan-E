import uuid
from datetime import date, datetime
from typing import List, Optional
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field


class RoomTypeBase(BaseModel):
    name: str
    description: Optional[str] = None
    max_occupancy: int = 2
    bed_configuration: str = "1 King Bed"
    base_price_per_night: Decimal
    amenities: List[str] = Field(default_factory=list)
    images: List[str] = Field(default_factory=list)
    is_active: bool = True



class RoomTypeUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    max_occupancy: Optional[int] = None
    bed_configuration: Optional[str] = None
    base_price_per_night: Optional[Decimal] = None
    amenities: Optional[List[str]] = None
    images: Optional[List[str]] = None
    is_active: Optional[bool] = None

class RoomTypeCreate(RoomTypeBase):
    property_id: uuid.UUID


class RoomAllocationCreate(BaseModel):
    room_type_id: uuid.UUID
    allocation_date: date
    total_allocated: int = Field(..., ge=0)
    rate_multiplier: Decimal = Field(default=Decimal("1.00"), gt=0)
    is_closed: bool = False


class RoomAllocationBatchCreate(BaseModel):
    room_type_id: uuid.UUID
    start_date: date
    end_date: date
    total_allocated: int = Field(..., ge=0)
    rate_multiplier: Decimal = Field(default=Decimal("1.00"), gt=0)
    is_closed: bool = False


class RoomAllocationResponse(BaseModel):
    id: uuid.UUID
    room_type_id: uuid.UUID
    allocation_date: date
    total_allocated: int
    booked_count: int
    available_count: int
    rate_multiplier: Decimal
    effective_price: Decimal
    is_closed: bool

    model_config = ConfigDict(from_attributes=True)


class RoomTypeResponse(RoomTypeBase):
    id: uuid.UUID
    property_id: uuid.UUID
    available_rooms: Optional[int] = None
    current_price_per_night: Optional[Decimal] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
