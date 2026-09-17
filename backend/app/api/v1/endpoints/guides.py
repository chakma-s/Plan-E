import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.guide import LocalGuideSummary, LocalGuideDetail
from app.schemas.common import APIResponse
from app.api.deps import get_current_user
from app.models.user import User
from pydantic import BaseModel, ConfigDict
from app.services.guide_service import GuideService

router = APIRouter()


@router.get("", response_model=APIResponse[List[LocalGuideSummary]])
async def list_guides(
    specialty: Optional[str] = Query(None, description="Filter by tour specialty (e.g., Snorkeling, Hiking)"),
    language: Optional[str] = Query(None, description="Filter by spoken language (e.g., Spanish, Japanese)"),
    db: AsyncSession = Depends(get_db),
):
    """
    Explore certified Local Tour Guides across destinations.
    """
    guides = await GuideService.list_guides(db, specialty, language)
    return APIResponse(data=guides)


@router.get("/{guide_id}", response_model=APIResponse[LocalGuideDetail])
async def get_guide_detail(guide_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """
    Retrieve in-depth profile, credentials, certifications, and availability calendar for a Local Guide.
    """
    guide = await GuideService.get_guide_by_id(db, guide_id)
    return APIResponse(data=guide)


class GuideCreate(BaseModel):
    full_name: str
    headline: str
    bio: str
    profile_photo_url: str
    languages: list[str] = ["English"]
    years_of_experience: int = 2
    hourly_rate: float = 35.0
    daily_rate: float = 200.0
    specialties: list[str] = ["Cultural Tours"]
    resort_id: uuid.UUID | None = None
    is_verified: bool = True

class GuideUpdate(BaseModel):
    full_name: str | None = None
    headline: str | None = None
    bio: str | None = None
    profile_photo_url: str | None = None
    languages: list[str] | None = None
    years_of_experience: int | None = None
    hourly_rate: float | None = None
    daily_rate: float | None = None
    specialties: list[str] | None = None
    is_active: bool | None = None
    resort_id: uuid.UUID | None = None

from datetime import date, timedelta
class GuideAvailabilityCreate(BaseModel):
    availability_date: date
    is_available: bool = True
    
from app.models.guide import LocalGuide, GuideAvailability, ResortGuideAssociation

@router.post("", response_model=APIResponse[dict])
async def create_guide(
    guide_in: GuideCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    guide = LocalGuide(
        full_name=guide_in.full_name,
        headline=guide_in.headline,
        bio=guide_in.bio,
        profile_photo_url=guide_in.profile_photo_url,
        languages=guide_in.languages,
        years_of_experience=guide_in.years_of_experience,
        hourly_rate=guide_in.hourly_rate,
        daily_rate=guide_in.daily_rate,
        specialties=guide_in.specialties,
        is_verified=guide_in.is_verified,
        is_active=True
    )
    db.add(guide)
    await db.commit()
    await db.refresh(guide)

    # Seed 90 days of open availability calendar so guide can be immediately bundled
    today = date.today()
    for d in range(90):
        avail = GuideAvailability(
            guide_id=guide.id,
            availability_date=today + timedelta(days=d),
            is_available=True,
            is_booked=False
        )
        db.add(avail)

    # Automatically link to resort if specified
    if guide_in.resort_id:
        assoc = ResortGuideAssociation(
            resort_id=guide_in.resort_id,
            guide_id=guide.id,
            is_primary=True
        )
        db.add(assoc)

    await db.commit()
    return APIResponse(
        message="Guide registered and activated with 90-day calendar.",
        data={"id": str(guide.id), "full_name": guide.full_name, "is_verified": guide.is_verified}
    )

@router.patch("/{guide_id}", response_model=APIResponse[dict])
async def update_guide(
    guide_id: uuid.UUID,
    guide_in: GuideUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # In a real app, we'd check if current_user owns this guide profile
    from sqlalchemy import select
    stmt = select(LocalGuide).where(LocalGuide.id == guide_id)
    res = await db.execute(stmt)
    guide = res.scalar_one_or_none()
    if not guide:
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Guide not found.")
        
    update_data = guide_in.model_dump(exclude_unset=True)
    if "resort_id" in update_data:
        resort_id = update_data.pop("resort_id")
        from sqlalchemy import delete as sql_delete
        await db.execute(sql_delete(ResortGuideAssociation).where(ResortGuideAssociation.guide_id == guide_id))
        if resort_id:
            assoc = ResortGuideAssociation(
                resort_id=resort_id,
                guide_id=guide_id,
                is_primary=True,
            )
            db.add(assoc)

    for field, value in update_data.items():
        setattr(guide, field, value)
        
    await db.commit()
    return APIResponse(message="Guide updated successfully.", data={"id": str(guide.id)})

@router.delete("/{guide_id}", response_model=APIResponse[dict])
async def delete_guide(
    guide_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from sqlalchemy import select, delete as sql_delete
    stmt = select(LocalGuide).where(LocalGuide.id == guide_id)
    res = await db.execute(stmt)
    guide = res.scalar_one_or_none()
    if not guide:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Guide not found.")

    # Delete related records first
    await db.execute(sql_delete(GuideAvailability).where(GuideAvailability.guide_id == guide_id))
    await db.execute(sql_delete(ResortGuideAssociation).where(ResortGuideAssociation.guide_id == guide_id))
    await db.delete(guide)
    await db.commit()
    return APIResponse(message="Guide deleted successfully.", data={"id": str(guide_id)})

@router.post("/{guide_id}/availabilities", response_model=APIResponse[dict])
async def set_guide_availability(
    guide_id: uuid.UUID,
    avail_in: GuideAvailabilityCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from sqlalchemy import select
    stmt = select(GuideAvailability).where(
        GuideAvailability.guide_id == guide_id,
        GuideAvailability.availability_date == avail_in.availability_date
    )
    res = await db.execute(stmt)
    existing = res.scalar_one_or_none()
    
    if existing:
        existing.is_available = avail_in.is_available
    else:
        new_avail = GuideAvailability(
            guide_id=guide_id,
            availability_date=avail_in.availability_date,
            is_available=avail_in.is_available,
            is_booked=False
        )
        db.add(new_avail)
        
    await db.commit()
    return APIResponse(message="Availability updated.", data={"guide_id": guide_id, "date": str(avail_in.availability_date)})
