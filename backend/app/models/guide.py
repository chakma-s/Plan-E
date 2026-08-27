import uuid
from datetime import date
from typing import List, Optional, TYPE_CHECKING
from decimal import Decimal
from sqlalchemy import (
    String,
    Text,
    Numeric,
    Integer,
    Boolean,
    Date,
    ForeignKey,
    UniqueConstraint,
    Index,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UUIDPrimaryKeyMixin, TimestampMixin, UUID_TYPE, JSON_TYPE

if TYPE_CHECKING:
    from app.models.user import User, VendorProfile
    from app.models.property import Property
    from app.models.booking import GuideBookingItem
    from app.models.review import Review


class LocalGuide(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    Local Tour Guide Profile.
    Core entity powering the Local Guide Bundling feature for Resort reservations.
    """
    __tablename__ = "local_guides"

    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID_TYPE, ForeignKey("users.id", ondelete="SET NULL"), unique=True, nullable=True
    )
    vendor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID_TYPE, ForeignKey("vendor_profiles.id", ondelete="SET NULL"), nullable=True
    )
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    headline: Mapped[str] = mapped_column(String(255), nullable=False)
    bio: Mapped[str] = mapped_column(Text, nullable=False)
    profile_photo_url: Mapped[str] = mapped_column(String(500), nullable=False)
    languages: Mapped[List[str]] = mapped_column(JSON_TYPE, default=lambda: ["English"], nullable=False)
    years_of_experience: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    license_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    hourly_rate: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("35.00"), nullable=False)
    daily_rate: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("200.00"), nullable=False)
    specialties: Mapped[List[str]] = mapped_column(JSON_TYPE, default=list, nullable=False)
    rating: Mapped[Decimal] = mapped_column(Numeric(3, 2), default=Decimal("5.00"), nullable=False)
    review_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    user: Mapped[Optional["User"]] = relationship("User", back_populates="guide_profile")
    vendor: Mapped[Optional["VendorProfile"]] = relationship("VendorProfile", back_populates="guides")
    resort_associations: Mapped[List["ResortGuideAssociation"]] = relationship(
        "ResortGuideAssociation", back_populates="guide", cascade="all, delete-orphan"
    )
    availabilities: Mapped[List["GuideAvailability"]] = relationship(
        "GuideAvailability", back_populates="guide", cascade="all, delete-orphan"
    )
    booking_items: Mapped[List["GuideBookingItem"]] = relationship(
        "GuideBookingItem", back_populates="guide"
    )
    reviews: Mapped[List["Review"]] = relationship("Review", back_populates="guide")

    __table_args__ = (
        Index("ix_local_guides_rating", "rating"),
    )


class ResortGuideAssociation(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    Many-to-Many join between Resorts and Local Guides.
    """
    __tablename__ = "resort_guide_associations"

    resort_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("properties.id", ondelete="CASCADE"), nullable=False
    )
    guide_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("local_guides.id", ondelete="CASCADE"), nullable=False
    )
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    resort: Mapped["Property"] = relationship("Property", back_populates="guide_associations")
    guide: Mapped["LocalGuide"] = relationship("LocalGuide", back_populates="resort_associations")

    __table_args__ = (
        UniqueConstraint("resort_id", "guide_id", name="uq_resort_guide"),
        Index("ix_resort_guide_lookup", "resort_id", "guide_id"),
    )


class GuideAvailability(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    Daily availability calendar for local guides.
    """
    __tablename__ = "guide_availabilities"

    guide_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("local_guides.id", ondelete="CASCADE"), nullable=False
    )
    availability_date: Mapped[date] = mapped_column(Date, nullable=False)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_booked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    guide: Mapped["LocalGuide"] = relationship("LocalGuide", back_populates="availabilities")

    __table_args__ = (
        UniqueConstraint("guide_id", "availability_date", name="uq_guide_date"),
        Index("ix_guide_avail_lookup", "guide_id", "availability_date", "is_available", "is_booked"),
    )
