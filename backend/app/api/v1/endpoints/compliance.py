"""
Plan-E: Global Compliance & Regional Policy REST Endpoints.

Provides:
- Policy inspection (active region, currency, tax mode, statutory disclosures)
- GDPR / CCPA Right to Data Portability (export-my-data)
- GDPR Right to Erasure / Anonymization (anonymize-my-account)
"""

import uuid
from typing import Dict, Any
from fastapi import APIRouter, Depends, status, Request
from sqlalchemy import select, update
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.regional_policy import RegionalPolicyManager, RegionalPolicy
from app.api.deps import get_current_user
from app.models.user import User
from app.models.booking import Reservation, RoomBookingItem, GuideBookingItem
from app.models.review import Review
from app.schemas.common import APIResponse

router = APIRouter()


@router.get("/policy", response_model=APIResponse[RegionalPolicy])
async def get_active_policy(request: Request):
    """
    Retrieve active regional compliance policy, legal disclosures, and pricing rules.
    Detects region via 'X-Region-Code' header if provided by client or CDN/Cloudflare.
    """
    region_header = request.headers.get("x-region-code") or request.headers.get("cf-ipcountry")
    policy = RegionalPolicyManager.get_policy(region_header)
    return APIResponse(data=policy)


@router.post("/export-my-data", response_model=APIResponse[Dict[str, Any]])
async def export_user_data(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    GDPR Article 20 / CCPA Data Portability Compliance:
    Exports all personal records, booking history, and reviews in machine-readable JSON.
    """
    # Fetch user reservations
    stmt_res = (
        select(Reservation)
        .where(Reservation.user_id == current_user.id)
        .options(
            selectinload(Reservation.room_items),
            selectinload(Reservation.guide_items),
        )
    )
    res_result = await db.execute(stmt_res)
    reservations = res_result.scalars().all()

    # Fetch user reviews
    stmt_rev = select(Review).where(Review.user_id == current_user.id)
    rev_result = await db.execute(stmt_rev)
    reviews = rev_result.scalars().all()

    export_payload = {
        "profile": {
            "id": str(current_user.id),
            "email": current_user.email,
            "full_name": current_user.full_name,
            "phone_number": current_user.phone_number,
            "role": current_user.role.value,
            "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
        },
        "reservations": [
            {
                "id": str(r.id),
                "reservation_code": r.reservation_code,
                "property_id": str(r.property_id),
                "status": r.status.value,
                "check_in_date": r.check_in_date.isoformat(),
                "check_out_date": r.check_out_date.isoformat(),
                "total_amount": float(r.total_amount),
                "currency": r.currency,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in reservations
        ],
        "reviews": [
            {
                "id": str(rev.id),
                "property_id": str(rev.property_id),
                "rating": rev.rating,
                "comment": rev.comment,
                "created_at": rev.created_at.isoformat() if rev.created_at else None,
            }
            for rev in reviews
        ],
        "data_processing_notice": "Data exported per statutory data subject rights request.",
    }

    return APIResponse(
        message="Personal data export generated successfully.",
        data=export_payload,
    )


@router.post("/anonymize-my-account", response_model=APIResponse[Dict[str, str]])
async def anonymize_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    GDPR Article 17 Right to Erasure / Anonymization:
    Anonymizes user PII while preserving aggregate financial transaction integrity for tax audits.
    """
    anon_id = uuid.uuid4().hex[:8]
    current_user.email = f"anonymized_{anon_id}@deleted.invalid"
    current_user.full_name = "Anonymized Traveler"
    current_user.phone_number = None
    current_user.is_active = False

    await db.commit()
    return APIResponse(
        message="Account successfully anonymized and scrubbed per data privacy regulations.",
        data={"status": "anonymized", "user_id": str(current_user.id)},
    )
