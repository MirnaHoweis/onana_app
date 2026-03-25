import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr

from app.models.email_draft import RecipientType


class EmailDraftCreate(BaseModel):
    subject: str
    body: str
    recipient_type: RecipientType
    recipient_email: Optional[str] = None
    request_id: Optional[uuid.UUID] = None


class EmailDraftUpdate(BaseModel):
    subject: Optional[str] = None
    body: Optional[str] = None
    recipient_type: Optional[RecipientType] = None
    recipient_email: Optional[str] = None


class EmailDraftOut(BaseModel):
    id: uuid.UUID
    subject: str
    body: str
    recipient_type: RecipientType
    recipient_email: Optional[str]
    request_id: Optional[uuid.UUID]
    is_sent: bool
    sent_at: Optional[datetime]
    created_by: uuid.UUID
    created_at: datetime

    model_config = {"from_attributes": True}


class SendEmailRequest(BaseModel):
    to_email: Optional[str] = None  # override recipient_email if provided
