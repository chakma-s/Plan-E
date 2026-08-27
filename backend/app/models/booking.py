import enum
import uuid
from datetime import date
from typing import List, Optional, TYPE_CHECKING
from decimal import Decimal
from sqlalchemy import (
    String,
    Text,
    Numeric,
    Integer,
    Date,
    ForeignKey,
    Enum as SQLEnum,
    CheckConstraint,
    Index,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UUIDPrimaryKeyMixin, TimestampMixin, UUID_TYPE

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.property import Property
    from app.models.room import RoomType
    from app.models.guide import LocalGuide
    from app.models.review import Review


class BookingType(str, enum.Enum):
    HOTEL_ONLY = "HOTEL_ONLY"
    RESORT_ONLY = "RESORT_ONLY"
    RESORT_WITH_GUIDE = "RESORT_WITH_GUIDE"


class BookingStatus(str, enum.Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"
    REFUNDED = "REFUNDED"


class PaymentStatus(str, enum.Enum):
    UNPAID = "UNPAID"
    PAID = "PAID"
    REFUNDED = "REFUNDED"
    FAILED = "FAILED"


class Reservation(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    Consolidated Reservation Entity.
    Handles Hotel bookings, Resort bookings, and Bundled Resort + Local Guide bookings.
    """
    __tablename__ = "reservations"

    reservation_code: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("properties.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    booking_type: Mapped[BookingType] = mapped_column(
        SQLEnum(BookingType, name="booking_type", create_type=False),
        nullable=False,
    )
    status: Mapped[BookingStatus] = mapped_column(
        SQLEnum(BookingStatus, name="booking_status", create_type=False),
        default=BookingStatus.PENDING,
        nullable=False,
        index=True,
    )
    payment_status: Mapped[PaymentStatus] = mapped_column(
        SQLEnum(PaymentStatus, name="payment_status", create_type=False),
        default=PaymentStatus.UNPAID,
        nullable=False,
    )
    idempotency_key: Mapped[Optional[str]] = mapped_column(String(100), unique=True, nullable=True)

    # Dates & Stay Information
    check_in_date: Mapped[date] = mapped_column(Date, nullable=False)
    check_out_date: Mapped[date] = mapped_column(Date, nullable=False)
    total_nights: Mapped[int] = mapped_column(Integer, nullable=False)
    guest_count: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    # Financial Breakdown
    room_subtotal: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("0.00"), nullable=False)
    guide_subtotal: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("0.00"), nullable=False)
    platform_fee: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("0.00"), nullable=False)
    tax_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("0.00"), nullable=False)
    total_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="USD", nullable=False)

    special_requests: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="reservations")
    property: Mapped["Property"] = relationship("Property", back_populates="reservations")
    room_items: Mapped[List["RoomBookingItem"]] = relationship(
        "RoomBookingItem", back_populates="reservation", cascade="all, delete-orphan"
    )
    guide_items: Mapped[List["GuideBookingItem"]] = relationship(
        "GuideBookingItem", back_populates="reservation", cascade="all, delete-orphan"
    )
    reviews: Mapped[List["Review"]] = relationship(
        "Review", back_populates="reservation", cascade="all, delete-orphan"
    )

    __table_args__ = (
        CheckConstraint("total_nights > 0", name="chk_total_nights_positive"),
        CheckConstraint("guest_count > 0", name="chk_guest_count_positive"),
        CheckConstraint("check_out_date > check_in_date", name="chk_checkout_gt_checkin"),
        CheckConstraint("total_amount >= 0", name="chk_total_amount_non_negative"),
    )


class RoomBookingItem(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "room_booking_items"

    reservation_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("reservations.id", ondelete="CASCADE"), nullable=False, index=True
    )
    room_type_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("room_types.id", ondelete="RESTRICT"), nullable=False
    )
    rooms_count: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    price_per_night: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    total_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)

    # Relationships
    reservation: Mapped["Reservation"] = relationship("Reservation", back_populates="room_items")
    room_type: Mapped["RoomType"] = relationship("RoomType", back_populates="booking_items")


class GuideBookingItem(Base, UUIDPrimaryKeyMixin):
    """
    Bundled local guide item attached to a consolidated reservation.
    """
    __tablename__ = "guide_booking_items"

    reservation_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("reservations.id", ondelete="CASCADE"), nullable=False, index=True
    )
    guide_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("local_guides.id", ondelete="RESTRICT"), nullable=False
    )
    service_date: Mapped[date] = mapped_column(Date, nullable=False)
    duration_days: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    daily_rate: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    total_guide_fee: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    special_requirements: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    reservation: Mapped["Reservation"] = relationship("Reservation", back_populates="guide_items")
    guide: Mapped["LocalGuide"] = relationship("LocalGuide", back_populates="booking_items")
