import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.api.deps import get_current_active_vendor
from app.models.user import User
from app.schemas.property import PropertyCreate, PropertyUpdate, PropertyDetailResponse
from app.schemas.room import (
    RoomTypeCreate, RoomTypeUpdate,
    RoomTypeResponse,
    RoomAllocationBatchCreate,
    RoomAllocationResponse,
)
from app.schemas.common import APIResponse
from app.services.vendor_service import VendorService

router = APIRouter()


@router.get("/properties", response_model=APIResponse[List[dict]])
async def get_my_properties(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    props = await VendorService.get_vendor_properties(db, profile.id)
    data = [
        {
            "id": p.id,
            "property_type": p.property_type.value,
            "name": p.name,
            "slug": p.slug,
            "city": p.city,
            "star_rating": float(p.star_rating),
            "is_published": p.is_published,
            "room_types_count": len(p.room_types),
        }
        for p in props
    ]
    return APIResponse(data=data)


@router.post("/properties", response_model=APIResponse[dict], status_code=status.HTTP_201_CREATED)
async def create_property(
    prop_in: PropertyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    prop = await VendorService.create_property(db, profile.id, prop_in)
    return APIResponse(
        message="Property created successfully.",
        data={"id": prop.id, "name": prop.name, "slug": prop.slug, "type": prop.property_type.value},
    )


@router.post("/rooms", response_model=APIResponse[dict], status_code=status.HTTP_201_CREATED)
async def create_room_type(
    room_in: RoomTypeCreate, RoomTypeUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    room = await VendorService.create_room_type(db, profile.id, room_in)
    return APIResponse(
        message="Room type created successfully.",
        data={"id": room.id, "name": room.name, "base_price": float(room.base_price_per_night)},
    )


@router.post("/allocations/batch", response_model=APIResponse[List[RoomAllocationResponse]])
async def set_room_allocations_batch(
    batch_in: RoomAllocationBatchCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    """
    Vendor Allocation Engine: Set or update room inventory quotas for a date range.
    """
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    allocations = await VendorService.set_room_allocations_batch(db, profile.id, batch_in)
    return APIResponse(
        message=f"Allocations updated for {len(allocations)} dates.",
        data=allocations,
    )


@router.post("/resorts/{resort_id}/guides/{guide_id}", response_model=APIResponse[dict])
async def link_guide_to_resort(
    resort_id: uuid.UUID,
    guide_id: uuid.UUID,
    is_primary: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    """
    Associate a certified Local Guide to a Resort for the Local Guide Bundling feature.
    """
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    await VendorService.link_guide_to_resort(db, profile.id, resort_id, guide_id, is_primary)
    return APIResponse(message="Local Guide successfully linked to resort roster.", data={"linked": True})


@router.patch("/properties/{property_id}", response_model=APIResponse[dict])
async def update_property(
    property_id: uuid.UUID,
    prop_in: PropertyUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    prop = await VendorService.update_property(db, profile.id, property_id, prop_in)
    return APIResponse(message="Property updated successfully.", data={"id": prop.id})

@router.delete("/properties/{property_id}", response_model=APIResponse[dict])
async def delete_property(
    property_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    await VendorService.delete_property(db, profile.id, property_id)
    return APIResponse(message="Property deleted successfully.", data={"id": property_id})

@router.patch("/rooms/{room_id}", response_model=APIResponse[dict])
async def update_room_type(
    room_id: uuid.UUID,
    room_in: RoomTypeUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    room = await VendorService.update_room_type(db, profile.id, room_id, room_in)
    return APIResponse(message="Room updated successfully.", data={"id": room.id})

@router.delete("/rooms/{room_id}", response_model=APIResponse[dict])
async def delete_room_type(
    room_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    await VendorService.delete_room_type(db, profile.id, room_id)
    return APIResponse(message="Room deleted successfully.", data={"id": room_id})

from datetime import date
@router.get("/allocations", response_model=APIResponse[List[RoomAllocationResponse]])
async def get_allocations(
    room_type_id: uuid.UUID,
    start_date: date,
    end_date: date,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_vendor),
):
    profile = await VendorService.get_vendor_profile(db, current_user.id)
    allocations = await VendorService.get_allocations(db, profile.id, room_type_id, start_date, end_date)
    return APIResponse(data=allocations)
