import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base
from app.models.base import TimestampMixin, new_uuid


class RecipientType(PyEnum):
    ACCOUNTING = "ACCOUNTING"
    SUPPLIER = "SUPPLIER"
    STOREKEEPER = "STOREKEEPER"


class EmailDraft(Base, TimestampMixin):
    __tablename__ = "email_drafts"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=new_uuid
    )
    subject: Mapped[str] = mapped_column(String(512), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    recipient_type: Mapped[RecipientType] = mapped_column(
        Enum(RecipientType), nullable=False
    )
    recipient_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    request_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("requests.id"), nullable=True
    )
    is_sent: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    sent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
