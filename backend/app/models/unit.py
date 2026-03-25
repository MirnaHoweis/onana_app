import uuid
from enum import Enum as PyEnum

from sqlalchemy import Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base
from app.models.base import TimestampMixin, new_uuid


class UnitType(PyEnum):
    VILLA = "VILLA"
    APARTMENT = "APARTMENT"
    COMMERCIAL = "COMMERCIAL"


class Unit(Base, TimestampMixin):
    __tablename__ = "units"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=new_uuid
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    type: Mapped[UnitType] = mapped_column(Enum(UnitType), nullable=False)
    floor: Mapped[str | None] = mapped_column(String(50), nullable=True)
    block: Mapped[str | None] = mapped_column(String(50), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    project: Mapped["Project"] = relationship("Project", back_populates="units")  # noqa: F821
    requests: Mapped[list["Request"]] = relationship("Request", back_populates="unit")  # noqa: F821
