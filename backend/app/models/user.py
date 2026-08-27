import enum
import uuid
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import String, Boolean, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UUIDPrimaryKeyMixin, TimestampMixin, UUID_TYPE

if TYPE_CHECKING:
    from app.models.property import Property
    from app.models.guide import LocalGuide
    from app.models.booking import Reservation
    from app.models.review import Review


class UserRole(str, enum.Enum):
    CUSTOMER = "CUSTOMER"
    VENDOR = "VENDOR"
    ADMIN = "ADMIN"
    GUIDE = "GUIDE"


class User(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone_number: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        SQLEnum(UserRole, name="user_role", create_type=False),
        default=UserRole.CUSTOMER,
        nullable=False,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    vendor_profile: Mapped[Optional["VendorProfile"]] = relationship(
        "VendorProfile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    guide_profile: Mapped[Optional["LocalGuide"]] = relationship(
        "LocalGuide", back_populates="user", uselist=False
    )
    reservations: Mapped[List["Reservation"]] = relationship("Reservation", back_populates="user")
    reviews: Mapped[List["Review"]] = relationship("Review", back_populates="user")


class VendorProfile(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "vendor_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    business_name: Mapped[str] = mapped_column(String(255), nullable=False)
    tax_id: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    contact_email: Mapped[str] = mapped_column(String(255), nullable=False)
    contact_phone: Mapped[str] = mapped_column(String(50), nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="vendor_profile")
    properties: Mapped[List["Property"]] = relationship("Property", back_populates="vendor")
    guides: Mapped[List["LocalGuide"]] = relationship("LocalGuide", back_populates="vendor")
