import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.user import User
from app.schemas.emails import EmailDraftCreate, EmailDraftOut, EmailDraftUpdate, SendEmailRequest
from app.services import email_service

router = APIRouter()


@router.get("/drafts", response_model=list[EmailDraftOut])
async def list_drafts(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await email_service.list_drafts(db, current_user.id)


@router.post("/drafts", response_model=EmailDraftOut, status_code=status.HTTP_201_CREATED)
async def create_draft(
    payload: EmailDraftCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await email_service.create_draft(db, payload, current_user.id)


@router.get("/drafts/{draft_id}", response_model=EmailDraftOut)
async def get_draft(
    draft_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    draft = await email_service.get_draft(db, draft_id, current_user.id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    return draft


@router.patch("/drafts/{draft_id}", response_model=EmailDraftOut)
async def update_draft(
    draft_id: uuid.UUID,
    payload: EmailDraftUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    draft = await email_service.get_draft(db, draft_id, current_user.id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    return await email_service.update_draft(db, draft, payload)


@router.delete("/drafts/{draft_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_draft(
    draft_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    draft = await email_service.get_draft(db, draft_id, current_user.id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    await email_service.delete_draft(db, draft)


@router.post("/drafts/{draft_id}/send", response_model=EmailDraftOut)
async def send_draft(
    draft_id: uuid.UUID,
    payload: SendEmailRequest = SendEmailRequest(),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    draft = await email_service.get_draft(db, draft_id, current_user.id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    if draft.is_sent:
        raise HTTPException(status_code=400, detail="Email already sent")
    try:
        return await email_service.send_draft(db, draft, payload.to_email)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception:
        raise HTTPException(status_code=502, detail="Failed to send email via SendGrid")
