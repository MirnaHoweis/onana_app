import uuid
from typing import List, Optional

from pydantic import BaseModel


class SuggestActionsRequest(BaseModel):
    request_id: uuid.UUID
    context: Optional[str] = None  # extra context the caller wants to include


class SuggestedAction(BaseModel):
    action: str
    reason: str
    priority: str  # "high" | "medium" | "low"


class SuggestActionsResponse(BaseModel):
    request_id: uuid.UUID
    actions: List[SuggestedAction]


class DetectDelaysRequest(BaseModel):
    project_id: Optional[uuid.UUID] = None  # None = scan all user projects


class DelayAlert(BaseModel):
    request_id: uuid.UUID
    title: str
    stage: str
    days_overdue: int
    recommendation: str


class DetectDelaysResponse(BaseModel):
    alerts: List[DelayAlert]


class DailySummaryResponse(BaseModel):
    summary: str
    highlights: List[str]
    pending_count: int
    overdue_count: int


class NoteToTaskRequest(BaseModel):
    note_text: str
    request_id: Optional[uuid.UUID] = None  # link result to a request if provided


class ExtractedTask(BaseModel):
    title: str
    description: str
    priority: str  # "high" | "medium" | "low"
    due_hint: Optional[str] = None  # e.g. "by end of week"


class NoteToTaskResponse(BaseModel):
    tasks: List[ExtractedTask]
