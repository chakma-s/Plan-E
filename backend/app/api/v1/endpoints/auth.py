from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import create_access_token
from app.schemas.user import (
    UserCreate,
    UserLogin,
    UserResponse,
    Token,
    VendorProfileCreate,
    VendorProfileResponse,
    SendOTPRequest,
    SendOTPResponse,
    VerifyOTPRequest,
)
from app.schemas.common import APIResponse
from app.services.auth_service import AuthService
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()


@router.post("/register", response_model=APIResponse[UserResponse], status_code=status.HTTP_201_CREATED)
async def register(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    user = await AuthService.register_user(db, user_in)
    return APIResponse(message="User registered successfully.", data=UserResponse.model_validate(user))


@router.post("/login", response_model=APIResponse[Token])
async def login(login_in: UserLogin, db: AsyncSession = Depends(get_db)):
    user = await AuthService.authenticate_user(db, login_in)
    access_token = create_access_token(subject=str(user.id))
    return APIResponse(
        message="Login successful.",
        data=Token(
            access_token=access_token,
            token_type="bearer",
            user=UserResponse.model_validate(user),
        ),
    )


@router.get("/me", response_model=APIResponse[UserResponse])
async def get_me(current_user: User = Depends(get_current_user)):
    return APIResponse(data=UserResponse.model_validate(current_user))


@router.post("/vendor-profile", response_model=APIResponse[VendorProfileResponse], status_code=status.HTTP_201_CREATED)
async def create_vendor_profile(
    vendor_in: VendorProfileCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = await AuthService.create_vendor_profile(db, current_user.id, vendor_in)
    return APIResponse(
        message="Vendor profile created successfully.",
        data=VendorProfileResponse.model_validate(profile),
    )


@router.post("/otp/send", response_model=APIResponse[SendOTPResponse])
async def send_otp(otp_in: SendOTPRequest, db: AsyncSession = Depends(get_db)):
    """Dispatch a 6-digit OTP to user's Email (Gmail) or Mobile Phone."""
    res = await AuthService.send_otp(db, otp_in)
    return APIResponse(message=res.message, data=res)


@router.post("/otp/verify", response_model=APIResponse[Token])
async def verify_otp(verify_in: VerifyOTPRequest, db: AsyncSession = Depends(get_db)):
    """Validate 6-digit OTP code and authenticate/register user seamlessly."""
    token = await AuthService.verify_otp(db, verify_in)
    return APIResponse(message="Authentication verified successfully.", data=token)

