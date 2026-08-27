import enum
import uuid
from typing import Optional, TYPE_CHECKING
from sqlalchemy import (
    Text,
    Integer,
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
    from app.models.guide import LocalGuide
    from app.models.booking import Reservation


class ReviewTargetType(str, enum.Enum):
    PROPERTY = "PROPERTY"
    GUIDE = "GUIDE"


class Review(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "reviews"

    reservation_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("reservations.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID_TYPE, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    target_type: Mapped[ReviewTargetType] = mapped_column(
        SQLEnum(ReviewTargetType, name="review_target_type", create_type=False),
        nullable=False,
    )
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID_TYPE, ForeignKey("properties.id", ondelete="CASCADE"), nullable=True
    )
    guide_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID_TYPE, ForeignKey("local_guides.id", ondelete="CASCADE"), nullable=True
    )
    rating: Mapped[int] = mapped_column(Integer, nullable=False)
    comment: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    reservation: Mapped["Reservation"] = relationship("Reservation", back_populates="reviews")
    user: Mapped["User"] = relationship("User", back_populates="reviews")
    property: Mapped[Optional["Property"]] = relationship("Property", back_populates="reviews")
    guide: Mapped[Optional["LocalGuide"]] = relationship("LocalGuide", back_populates="reviews")

    __table_args__ = (
        CheckConstraint("rating >= 1 AND rating <= 5", name="chk_review_rating_range"),
        Index("ix_reviews_property", "property_id"),
        Index("ix_reviews_guide", "guide_id"),
    )
