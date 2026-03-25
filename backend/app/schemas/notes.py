import uuid
from typing import Optional

from pydantic import BaseModel


class NoteCreate(BaseModel):
    title: str
    content: Optional[str] = None
    voice_url: Optional[str] = None
    project_id: Optional[uuid.UUID] = None
    unit_id: Optional[uuid.UUID] = None
    request_id: Optional[uuid.UUID] = None


class NoteUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None


class NoteOut(BaseModel):
    id: uuid.UUID
    title: str
    content: Optional[str]
    voice_url: Optional[str]
    project_id: Optional[uuid.UUID]
    unit_id: Optional[uuid.UUID]
    request_id: Optional[uuid.UUID]
    created_by: uuid.UUID
    created_at: str

    model_config = {"from_attributes": True}
