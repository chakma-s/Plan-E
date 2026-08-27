import enum
import uuid
from datetime import time
from typing import List, Optional, Any, TYPE_CHECKING
from decimal import Decimal
from sqlalchemy import (
    String,
    Text,
    Numeric,
    Integer,
    Boolean,
    Time,
    ForeignKey,
    Enum as SQLEnum,
    Index,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UUIDPrimaryKeyMixin, TimestampMixin, UUID_TYPE, JSON_TYPE

if TYPE_CHECKING:
    from app.models.user import VendorProfile
    from app.models.room import RoomType
    from app.models.guide import ResortGuideAssociation
    from app.models.booking import Reservation
    from app.models.review import Review


class PropertyType(str, enum.Enum):
    HOTEL = "HOTEL"
    RESORT = "RESORT"


class Property(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "properties"

    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("vendor_profiles.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    property_type: Mapped[PropertyType] = mapped_column(
        SQLEnum(PropertyType, name="property_type", create_type=False),
        nullable=False,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    slug: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    tagline: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # Location & Mapbox Spatial Data
    address: Mapped[str] = mapped_column(String(255), nullable=False)
    city: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    state: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    country: Mapped[str] = mapped_column(String(100), nullable=False)
    postal_code: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    latitude: Mapped[Decimal] = mapped_column(Numeric(10, 7), nullable=False)
    longitude: Mapped[Decimal] = mapped_column(Numeric(10, 7), nullable=False)

    # Ratings & Presentation
    star_rating: Mapped[Decimal] = mapped_column(Numeric(2, 1), default=Decimal("4.0"), nullable=False)
    review_score: Mapped[Decimal] = mapped_column(Numeric(3, 2), default=Decimal("0.00"), nullable=False)
    review_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    cover_image_url: Mapped[str] = mapped_column(String(500), nullable=False)
    gallery_images: Mapped[List[str]] = mapped_column(JSON_TYPE, default=list, nullable=False)
    amenities: Mapped[List[str]] = mapped_column(JSON_TYPE, default=list, nullable=False)

    # Operational Rules
    check_in_time: Mapped[time] = mapped_column(Time, default=time(15, 0, 0), nullable=False)
    check_out_time: Mapped[time] = mapped_column(Time, default=time(11, 0, 0), nullable=False)
    cancellation_policy: Mapped[str] = mapped_column(
        Text, default="Free cancellation up to 48 hours before check-in.", nullable=False
    )
    is_published: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    vendor: Mapped["VendorProfile"] = relationship("VendorProfile", back_populates="properties")
    room_types: Mapped[List["RoomType"]] = relationship(
        "RoomType", back_populates="property", cascade="all, delete-orphan"
    )
    guide_associations: Mapped[List["ResortGuideAssociation"]] = relationship(
        "ResortGuideAssociation", back_populates="resort", cascade="all, delete-orphan"
    )
    reservations: Mapped[List["Reservation"]] = relationship("Reservation", back_populates="property")
    reviews: Mapped[List["Review"]] = relationship("Review", back_populates="property")

    __table_args__ = (
        Index("ix_properties_geo", "latitude", "longitude"),
        Index("ix_properties_type_geo", "property_type", "latitude", "longitude"),
    )
