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
    CheckConstraint,
    Index,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UUIDPrimaryKeyMixin, TimestampMixin, UUID_TYPE, JSON_TYPE

if TYPE_CHECKING:
    from app.models.property import Property
    from app.models.booking import RoomBookingItem


class RoomType(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "room_types"

    property_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("properties.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    max_occupancy: Mapped[int] = mapped_column(Integer, default=2, nullable=False)
    bed_configuration: Mapped[str] = mapped_column(String(100), default="1 King Bed", nullable=False)
    base_price_per_night: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    amenities: Mapped[List[str]] = mapped_column(JSON_TYPE, default=list, nullable=False)
    images: Mapped[List[str]] = mapped_column(JSON_TYPE, default=list, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    property: Mapped["Property"] = relationship("Property", back_populates="room_types")
    allocations: Mapped[List["RoomAllocation"]] = relationship(
        "RoomAllocation", back_populates="room_type", cascade="all, delete-orphan"
    )
    booking_items: Mapped[List["RoomBookingItem"]] = relationship(
        "RoomBookingItem", back_populates="room_type"
    )


class RoomAllocation(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    The Core Vendor Allocation Model Table.
    Enforces atomic room availability and prevents overbooking.
    """
    __tablename__ = "room_allocations"

    room_type_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("room_types.id", ondelete="CASCADE"), nullable=False
    )
    allocation_date: Mapped[date] = mapped_column(Date, nullable=False)
    total_allocated: Mapped[int] = mapped_column(Integer, nullable=False)
    booked_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    rate_multiplier: Mapped[Decimal] = mapped_column(Numeric(4, 2), default=Decimal("1.00"), nullable=False)
    is_closed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    room_type: Mapped["RoomType"] = relationship("RoomType", back_populates="allocations")

    __table_args__ = (
        UniqueConstraint("room_type_id", "allocation_date", name="uq_room_type_date"),
        CheckConstraint("total_allocated >= 0", name="chk_total_allocated_non_negative"),
        CheckConstraint("booked_count >= 0", name="chk_booked_count_non_negative"),
        CheckConstraint("booked_count <= total_allocated", name="chk_booked_le_allocated"),
        Index("ix_allocations_lookup", "room_type_id", "allocation_date", "is_closed"),
    )
