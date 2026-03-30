import uuid
from datetime import date
from enum import Enum as PyEnum

from sqlalchemy import Date, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base
from app.models.base import SoftDeleteMixin, TimestampMixin, new_uuid


class RequestCategory(PyEnum):
    FURNITURE = "FURNITURE"
    APPLIANCE = "APPLIANCE"
    FINISHING = "FINISHING"
    OTHER = "OTHER"


class RequestStatus(PyEnum):
    MATERIAL_REQUEST = "MATERIAL_REQUEST"
    PO_REQUESTED = "PO_REQUESTED"
    PO_CREATED = "PO_CREATED"
    DELIVERY = "DELIVERY"
    STOREKEEPER_CONFIRMED = "STOREKEEPER_CONFIRMED"
    INSTALLATION_IN_PROGRESS = "INSTALLATION_IN_PROGRESS"
    INSTALLATION_COMPLETE = "INSTALLATION_COMPLETE"


class RequestPriority(PyEnum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    URGENT = "URGENT"


class Request(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "requests"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=new_uuid
    )
    unit_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("units.id"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    category: Mapped[RequestCategory] = mapped_column(
        Enum(RequestCategory), nullable=False
    )
    status: Mapped[RequestStatus] = mapped_column(
        Enum(RequestStatus),
        nullable=False,
        default=RequestStatus.MATERIAL_REQUEST,
    )
    priority: Mapped[RequestPriority] = mapped_column(
        Enum(RequestPriority), nullable=False, default=RequestPriority.MEDIUM
    )
    supplier_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    po_number: Mapped[str | None] = mapped_column(String(100), nullable=True)
    po_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    expected_delivery_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    actual_delivery_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    assigned_to: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    created_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )

    unit: Mapped["Unit"] = relationship("Unit", back_populates="requests")  # noqa: F821
    history: Mapped[list["RequestHistory"]] = relationship(  # noqa: F821
        "RequestHistory", back_populates="request"
    )
    installation: Mapped["Installation | None"] = relationship(  # noqa: F821
        "Installation", back_populates="request", uselist=False
    )
