import uuid
import secrets
from datetime import datetime, timezone, timedelta
from typing import Optional
from sqlalchemy import select, update, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.user import User, VendorProfile, UserRole, OTPVerification
from app.schemas.user import (
    UserCreate,
    UserLogin,
    VendorProfileCreate,
    SendOTPRequest,
    SendOTPResponse,
    VerifyOTPRequest,
    Token,
    UserResponse,
)
from app.core.security import get_password_hash, verify_password, create_access_token
from app.services.notification_service import NotificationService


class AuthService:
    @staticmethod
    async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
        stmt = select(User).where(User.email == email.lower().strip())
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    @staticmethod
    async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> Optional[User]:
        stmt = select(User).where(User.id == user_id)
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    @classmethod
    async def register_user(cls, db: AsyncSession, user_in: UserCreate) -> User:
        existing = await cls.get_user_by_email(db, user_in.email)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists."
            )
        
        user = User(
            email=user_in.email.lower().strip(),
            password_hash=get_password_hash(user_in.password),
            full_name=user_in.full_name,
            phone_number=user_in.phone_number,
            role=user_in.role,
            is_active=True,
            is_verified=False,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    @classmethod
    async def authenticate_user(cls, db: AsyncSession, login_in: UserLogin) -> User:
        user = await cls.get_user_by_email(db, login_in.email)
        if not user or not verify_password(login_in.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password."
            )
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is inactive."
            )
        return user

    @classmethod
    async def create_vendor_profile(
        cls, db: AsyncSession, user_id: uuid.UUID, vendor_in: VendorProfileCreate
    ) -> VendorProfile:
        user = await cls.get_user_by_id(db, user_id)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
        
        # Check if profile exists
        stmt = select(VendorProfile).where(VendorProfile.user_id == user_id)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Vendor profile already exists.")
        
        # Update user role to VENDOR if currently CUSTOMER
        if user.role == UserRole.CUSTOMER:
            user.role = UserRole.VENDOR
        
        vendor_profile = VendorProfile(
            user_id=user_id,
            business_name=vendor_in.business_name,
            tax_id=vendor_in.tax_id,
            contact_email=vendor_in.contact_email,
            contact_phone=vendor_in.contact_phone,
            is_verified=False,
        )
        db.add(vendor_profile)
        await db.commit()
        await db.refresh(vendor_profile)
        return vendor_profile

    @classmethod
    async def send_otp(cls, db: AsyncSession, req: SendOTPRequest) -> SendOTPResponse:
        raw_target = req.target.strip()
        if not raw_target:
            raise HTTPException(status_code=400, detail="Target email or phone number is required.")

        channel = "email" if "@" in raw_target else "phone"
        clean_target = raw_target.lower() if channel == "email" else "".join(ch for ch in raw_target if ch.isalnum() or ch == "+")

        if channel == "phone" and len(clean_target) < 7:
            raise HTTPException(status_code=400, detail="Invalid phone number format.")

        if req.purpose == "recovery":
            user_stmt = select(User).where(
                or_(User.email == clean_target.lower(), User.phone_number == clean_target)
            )
            user_res = await db.execute(user_stmt)
            if not user_res.scalar_one_or_none():
                raise HTTPException(status_code=404, detail="No registered account found with this target.")

        # Invalidate any prior active OTPs for this target
        stmt_inv = (
            update(OTPVerification)
            .where(
                and_(
                    OTPVerification.target == clean_target,
                    OTPVerification.is_used == False,
                )
            )
            .values(is_used=True)
        )
        await db.execute(stmt_inv)

        # Generate cryptographically secure 6-digit numeric OTP
        otp_code = f"{secrets.randbelow(900000) + 100000}"
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)

        otp_record = OTPVerification(
            target=clean_target,
            channel=channel,
            otp_code=otp_code,
            purpose=req.purpose,
            expires_at=expires_at,
            is_used=False,
            attempts=0,
        )
        db.add(otp_record)
        await db.commit()

        # Multi-channel notification delivery (Email or SMS)
        await NotificationService.dispatch_otp(
            target=clean_target,
            channel=channel,
            otp_code=otp_code,
            purpose=req.purpose,
        )

        return SendOTPResponse(
            message=f"Verification code successfully dispatched via {channel.upper()}.",
            target=clean_target,
            channel=channel,
            expires_in_seconds=600,
            dev_code_hint=otp_code,
        )

    @classmethod
    async def verify_otp(cls, db: AsyncSession, req: VerifyOTPRequest) -> Token:
        raw_target = req.target.strip()
        channel = "email" if "@" in raw_target else "phone"
        clean_target = raw_target.lower() if channel == "email" else "".join(ch for ch in raw_target if ch.isalnum() or ch == "+")
        provided_code = req.otp_code.strip()

        # Look up valid, unexpired, unused OTP
        stmt = (
            select(OTPVerification)
            .where(
                and_(
                    OTPVerification.target == clean_target,
                    OTPVerification.is_used == False,
                    OTPVerification.expires_at >= datetime.now(timezone.utc),
                )
            )
            .order_by(OTPVerification.created_at.desc())
        )
        res = await db.execute(stmt)
        otp_record = res.scalars().first()

        if not otp_record or otp_record.otp_code != provided_code:
            if otp_record:
                otp_record.attempts += 1
                if otp_record.attempts >= 5:
                    otp_record.is_used = True
                await db.commit()
            raise HTTPException(status_code=400, detail="Invalid or expired verification code.")

        # Mark OTP as successfully redeemed
        otp_record.is_used = True

        # Find or create traveler user
        user_stmt = select(User).where(
            or_(User.email == clean_target.lower(), User.phone_number == clean_target)
        )
        user_res = await db.execute(user_stmt)
        user = user_res.scalar_one_or_none()

        if req.purpose == "recovery":
            if not user:
                raise HTTPException(status_code=404, detail="User account not found for password recovery.")
            if req.new_password:
                user.password_hash = get_password_hash(req.new_password)
                user.is_verified = True
                await db.commit()
                await db.refresh(user)
        else:
            if not user:
                # Instant frictionless account creation for new traveler
                assigned_email = clean_target if channel == "email" else f"traveler-{secrets.token_hex(4)}@plane-user.com"
                assigned_phone = clean_target if channel == "phone" else None
                display_name = req.full_name or (clean_target.split("@")[0].capitalize() if channel == "email" else "Traveler")
                temp_hash = get_password_hash(req.new_password or secrets.token_urlsafe(16))

                user = User(
                    email=assigned_email,
                    password_hash=temp_hash,
                    full_name=display_name,
                    phone_number=assigned_phone,
                    role=UserRole.CUSTOMER,
                    is_active=True,
                    is_verified=True,
                )
                db.add(user)
                await db.commit()
                await db.refresh(user)
            else:
                user.is_verified = True
                await db.commit()
                await db.refresh(user)

        # Issue signed JWT session token
        access_token = create_access_token(subject=str(user.id))
        return Token(
            access_token=access_token,
            token_type="bearer",
            user=UserResponse.model_validate(user),
        )

