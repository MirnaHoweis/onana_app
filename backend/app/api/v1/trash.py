"""
Trash — list, restore, and permanently delete soft-deleted records.

Supported types: project | request | note | email
"""
import uuid
from datetime import datetime, timezone
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.email_draft import EmailDraft
from app.models.note import Note
from app.models.project import Project
from app.models.request import Request
from app.models.unit import Unit
from app.models.user import User

router = APIRouter()

ItemType = Literal["project", "request", "note", "email"]


async def _get_or_404(db, model, item_id, user_id):
    """Fetch a soft-deleted record belonging to the current user."""
    result = await db.execute(
        select(model).where(
            model.id == item_id,
            model.deleted_at.isnot(None),
            model.created_by == user_id,
        )
    )
    obj = result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Item not found in trash")
    return obj


@router.get("")
async def list_trash(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return all soft-deleted items owned by the current user."""
    uid = current_user.id

    projects = (await db.execute(
        select(Project).where(Project.created_by == uid, Project.deleted_at.isnot(None))
        .order_by(Project.deleted_at.desc())
    )).scalars().all()

    requests = (await db.execute(
        select(Request).where(Request.created_by == uid, Request.deleted_at.isnot(None))
        .order_by(Request.deleted_at.desc())
    )).scalars().all()

    notes = (await db.execute(
        select(Note).where(Note.created_by == uid, Note.deleted_at.isnot(None))
        .order_by(Note.deleted_at.desc())
    )).scalars().all()

    emails = (await db.execute(
        select(EmailDraft).where(EmailDraft.created_by == uid, EmailDraft.deleted_at.isnot(None))
        .order_by(EmailDraft.deleted_at.desc())
    )).scalars().all()

    # Resolve unit names for requests
    unit_ids = list({r.unit_id for r in requests})
    unit_map: dict[uuid.UUID, str] = {}
    if unit_ids:
        unit_rows = (await db.execute(
            select(Unit.id, Unit.name).where(Unit.id.in_(unit_ids))
        )).all()
        unit_map = {row.id: row.name for row in unit_rows}

    return {
        "projects": [
            {"id": str(p.id), "name": p.name, "type": "project",
             "client_name": p.client_name, "deleted_at": p.deleted_at.isoformat()}
            for p in projects
        ],
        "requests": [
            {"id": str(r.id), "name": r.title, "type": "request",
             "unit_name": unit_map.get(r.unit_id, ""), "deleted_at": r.deleted_at.isoformat()}
            for r in requests
        ],
        "notes": [
            {"id": str(n.id), "name": n.title, "type": "note",
             "content": n.content, "deleted_at": n.deleted_at.isoformat()}
            for n in notes
        ],
        "emails": [
            {"id": str(e.id), "name": e.subject, "type": "email",
             "recipient_email": e.recipient_email, "deleted_at": e.deleted_at.isoformat()}
            for e in emails
        ],
    }


@router.post("/{item_type}/{item_id}/restore")
async def restore_item(
    item_type: ItemType,
    item_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    model = _model_for(item_type)
    obj = await _get_or_404(db, model, item_id, current_user.id)
    obj.deleted_at = None
    await db.commit()
    return {"restored": True, "type": item_type, "id": str(item_id)}


@router.delete("/{item_type}/{item_id}")
async def permanently_delete(
    item_type: ItemType,
    item_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    model = _model_for(item_type)
    obj = await _get_or_404(db, model, item_id, current_user.id)
    await db.delete(obj)
    await db.commit()
    return {"deleted_forever": True, "type": item_type, "id": str(item_id)}


def _model_for(item_type: ItemType):
    return {"project": Project, "request": Request, "note": Note, "email": EmailDraft}[item_type]
