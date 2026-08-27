import uuid
from datetime import date
from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.property import (
    ResortSearchParams,
    ResortCardResponse,
    PropertyDetailResponse,
)
from app.schemas.common import APIResponse
from app.services.resort_service import ResortService

router = APIRouter()


@router.get("", response_model=APIResponse[List[ResortCardResponse]])
async def search_resorts(
    destination: Optional[str] = Query(None, description="Destination, region, or resort name"),
    check_in: Optional[date] = Query(None, description="Check-in date"),
    check_out: Optional[date] = Query(None, description="Check-out date"),
    guests: int = Query(1, ge=1, description="Number of guests"),
    amenities: Optional[List[str]] = Query(None, description="Filter by amenities (e.g. Spa, Beachfront)"),
    min_lat: Optional[Decimal] = Query(None, description="Mapbox south latitude"),
    max_lat: Optional[Decimal] = Query(None, description="Mapbox north latitude"),
    min_lon: Optional[Decimal] = Query(None, description="Mapbox west longitude"),
    max_lon: Optional[Decimal] = Query(None, description="Mapbox east longitude"),
    with_guides_only: bool = Query(False, description="Only show resorts with available certified local guides"),
    sort_by: str = Query("featured", description="Sorting: featured, price_asc, rating_desc"),
    db: AsyncSession = Depends(get_db),
):
    """
    Dedicated Resort Pipeline Endpoint.
    Engineered for immersive vacation planning, luxury galleries, and Local Guide Bundling previews.
    """
    params = ResortSearchParams(
        destination=destination,
        check_in=check_in,
        check_out=check_out,
        guests=guests,
        amenities=amenities,
        min_lat=min_lat,
        max_lat=max_lat,
        min_lon=min_lon,
        max_lon=max_lon,
        with_guides_only=with_guides_only,
        sort_by=sort_by,
    )
    resorts = await ResortService.search_resorts(db, params)
    return APIResponse(data=resorts)


@router.get("/{resort_id}", response_model=APIResponse[PropertyDetailResponse])
async def get_resort_detail(
    resort_id: uuid.UUID,
    check_in: Optional[date] = Query(None, description="Optional check-in date for live pricing"),
    check_out: Optional[date] = Query(None, description="Optional check-out date for live pricing"),
    db: AsyncSession = Depends(get_db),
):
    """
    Fetch immersive resort details with room types, luxury imagery, and the complete certified Local Guide roster.
    """
    resort = await ResortService.get_resort_detail(db, resort_id, check_in, check_out)
    return APIResponse(data=resort)
