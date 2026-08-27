import uuid
from decimal import Decimal
from fastapi import APIRouter, Depends, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.api.deps import get_current_active_admin
from app.models.user import User
from app.models.property import Property, PropertyType
from app.models.guide import LocalGuide
from app.models.booking import Reservation, BookingStatus
from app.schemas.common import APIResponse

router = APIRouter()


@router.get("/overview", response_model=APIResponse[dict])
async def get_admin_overview(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    """
    Internal Admin Dashboard: Ecosystem Telemetry & Aggregated Metrics.
    """
    total_users_res = await db.execute(select(func.count(User.id)))
    total_users = total_users_res.scalar() or 0

    total_hotels_res = await db.execute(
        select(func.count(Property.id)).where(Property.property_type == PropertyType.HOTEL)
    )
    total_hotels = total_hotels_res.scalar() or 0

    total_resorts_res = await db.execute(
        select(func.count(Property.id)).where(Property.property_type == PropertyType.RESORT)
    )
    total_resorts = total_resorts_res.scalar() or 0

    total_guides_res = await db.execute(select(func.count(LocalGuide.id)))
    total_guides = total_guides_res.scalar() or 0

    total_res_stmt = select(
        func.count(Reservation.id),
        func.coalesce(func.sum(Reservation.total_amount), 0.0),
        func.coalesce(func.sum(Reservation.platform_fee), 0.0),
    ).where(Reservation.status == BookingStatus.CONFIRMED)
    res_stats = (await db.execute(total_res_stmt)).one()

    return APIResponse(
        data={
            "total_users": total_users,
            "total_hotels": total_hotels,
            "total_resorts": total_resorts,
            "total_guides": total_guides,
            "confirmed_bookings": res_stats[0],
            "gross_booking_volume": float(res_stats[1]),
            "total_platform_revenue": float(res_stats[2]),
        }
    )


@router.patch("/guides/{guide_id}/verify", response_model=APIResponse[dict])
async def toggle_guide_verification(
    guide_id: uuid.UUID,
    is_verified: bool,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    stmt = select(LocalGuide).where(LocalGuide.id == guide_id)
    res = await db.execute(stmt)
    guide = res.scalar_one_or_none()
    if not guide:
        from fastapi import HTTPException
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Local Guide not found.")
    guide.is_verified = is_verified
    await db.commit()
    return APIResponse(
        message=f"Local Guide verification status updated to {is_verified}.",
        data={"guide_id": guide.id, "is_verified": guide.is_verified},
    )


@router.patch("/properties/{property_id}/publish", response_model=APIResponse[dict])
async def publish_property(
    property_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_admin),
):
    stmt = select(Property).where(Property.id == property_id)
    res = await db.execute(stmt)
    prop = res.scalar_one_or_none()
    if not prop:
        from fastapi import HTTPException
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Property not found.")
    prop.is_published = True
    await db.commit()
    return APIResponse(message="Property published successfully.", data={"id": prop.id})
