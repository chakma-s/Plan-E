import uuid
from datetime import date
from typing import List, Optional
from decimal import Decimal
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.property import (
    HotelSearchParams,
    HotelCardResponse,
    PropertyDetailResponse,
)
from app.schemas.common import APIResponse
from app.services.hotel_service import HotelService

router = APIRouter()


@router.get("", response_model=APIResponse[List[HotelCardResponse]])
async def search_hotels(
    city: Optional[str] = Query(None, description="City or hotel name"),
    check_in: Optional[date] = Query(None, description="Check-in date"),
    check_out: Optional[date] = Query(None, description="Check-out date"),
    guests: int = Query(1, ge=1, description="Number of guests"),
    min_lat: Optional[Decimal] = Query(None, description="Mapbox south latitude"),
    max_lat: Optional[Decimal] = Query(None, description="Mapbox north latitude"),
    min_lon: Optional[Decimal] = Query(None, description="Mapbox west longitude"),
    max_lon: Optional[Decimal] = Query(None, description="Mapbox east longitude"),
    min_price: Optional[Decimal] = Query(None, description="Minimum price filter"),
    max_price: Optional[Decimal] = Query(None, description="Maximum price filter"),
    min_rating: Optional[Decimal] = Query(None, description="Minimum star rating"),
    sort_by: str = Query("recommended", description="Sorting: recommended, price_asc, price_desc, rating_desc"),
    db: AsyncSession = Depends(get_db),
):
    """
    Dedicated Hotel Pipeline Endpoint.
    Engineered for ultra-fast, lean payloads, and instant transactional booking discovery.
    """
    params = HotelSearchParams(
        city=city,
        check_in=check_in,
        check_out=check_out,
        guests=guests,
        min_lat=min_lat,
        max_lat=max_lat,
        min_lon=min_lon,
        max_lon=max_lon,
        min_price=min_price,
        max_price=max_price,
        min_rating=min_rating,
        sort_by=sort_by,
    )
    hotels = await HotelService.search_hotels(db, params)
    return APIResponse(data=hotels)


@router.get("/{hotel_id}", response_model=APIResponse[PropertyDetailResponse])
async def get_hotel_detail(
    hotel_id: uuid.UUID,
    check_in: Optional[date] = Query(None, description="Optional check-in date for live pricing"),
    check_out: Optional[date] = Query(None, description="Optional check-out date for live pricing"),
    db: AsyncSession = Depends(get_db),
):
    """
    Fetch comprehensive hotel details including active room types and live daily allocation rates.
    """
    hotel = await HotelService.get_hotel_detail(db, hotel_id, check_in, check_out)
    return APIResponse(data=hotel)
