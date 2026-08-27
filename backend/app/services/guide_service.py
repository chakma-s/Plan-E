import uuid
from datetime import date
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.guide import LocalGuide, GuideAvailability
from app.schemas.guide import LocalGuideDetail, LocalGuideSummary, GuideAvailabilityResponse


class GuideService:
    @staticmethod
    async def get_guide_by_id(db: AsyncSession, guide_id: uuid.UUID) -> LocalGuideDetail:
        stmt = (
            select(LocalGuide)
            .where(LocalGuide.id == guide_id)
            .options(selectinload(LocalGuide.availabilities))
        )
        result = await db.execute(stmt)
        guide = result.scalar_one_or_none()
        if not guide:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Local Guide not found.")

        avail_resp = [
            GuideAvailabilityResponse(
                id=av.id,
                guide_id=av.guide_id,
                availability_date=av.availability_date,
                is_available=av.is_available,
                is_booked=av.is_booked,
            )
            for av in guide.availabilities
        ]

        return LocalGuideDetail(
            id=guide.id,
            full_name=guide.full_name,
            headline=guide.headline,
            bio=guide.bio,
            profile_photo_url=guide.profile_photo_url,
            languages=guide.languages,
            years_of_experience=guide.years_of_experience,
            license_number=guide.license_number,
            hourly_rate=guide.hourly_rate,
            daily_rate=guide.daily_rate,
            specialties=guide.specialties,
            rating=guide.rating,
            review_count=guide.review_count,
            is_verified=guide.is_verified,
            is_active=guide.is_active,
            availabilities=avail_resp,
            created_at=guide.created_at,
        )

    @staticmethod
    async def list_guides(
        db: AsyncSession, specialty: Optional[str] = None, language: Optional[str] = None
    ) -> List[LocalGuideSummary]:
        stmt = select(LocalGuide).where(LocalGuide.is_active == True)
        result = await db.execute(stmt)
        guides = result.scalars().all()

        output: List[LocalGuideSummary] = []
        for g in guides:
            if specialty and specialty.lower() not in [s.lower() for s in g.specialties]:
                continue
            if language and language.lower() not in [l.lower() for l in g.languages]:
                continue
            output.append(
                LocalGuideSummary(
                    id=g.id,
                    full_name=g.full_name,
                    headline=g.headline,
                    profile_photo_url=g.profile_photo_url,
                    languages=g.languages,
                    daily_rate=g.daily_rate,
                    rating=g.rating,
                    review_count=g.review_count,
                    specialties=g.specialties,
                    is_verified=g.is_verified,
                )
            )
        return output
