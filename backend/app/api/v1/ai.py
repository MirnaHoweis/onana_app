import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.user import User
from app.schemas.ai import (
    DailySummaryResponse,
    DetectDelaysRequest,
    DetectDelaysResponse,
    NoteToTaskRequest,
    NoteToTaskResponse,
    SuggestActionsRequest,
    SuggestActionsResponse,
)
from app.services import ai_service

router = APIRouter()

_NO_KEY_MSG = "ANTHROPIC_API_KEY is not configured. Add it to your .env file to enable AI features."


def _handle_error(e: Exception) -> HTTPException:
    if isinstance(e, ValueError) and str(e) == "ANTHROPIC_API_KEY_NOT_SET":
        return HTTPException(status_code=503, detail=_NO_KEY_MSG)
    return HTTPException(status_code=502, detail=f"AI service error: {e}")


@router.post("/suggest-actions", response_model=SuggestActionsResponse)
async def suggest_actions(
    payload: SuggestActionsRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await ai_service.suggest_actions(db, payload.request_id, payload.context)
    except Exception as e:
        raise _handle_error(e)


@router.post("/detect-delays", response_model=DetectDelaysResponse)
async def detect_delays(
    payload: DetectDelaysRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await ai_service.detect_delays(db, current_user.id, payload.project_id)
    except Exception as e:
        raise _handle_error(e)


@router.get("/daily-summary", response_model=DailySummaryResponse)
async def daily_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await ai_service.daily_summary(db, current_user.id)
    except Exception as e:
        raise _handle_error(e)


@router.post("/note-to-task", response_model=NoteToTaskResponse)
async def note_to_task(
    payload: NoteToTaskRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        return await ai_service.note_to_task(payload.note_text)
    except Exception as e:
        raise _handle_error(e)
