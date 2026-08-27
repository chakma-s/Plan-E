import uuid
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.user import User, VendorProfile, UserRole
from app.schemas.user import UserCreate, UserLogin, VendorProfileCreate
from app.core.security import get_password_hash, verify_password, create_access_token


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
