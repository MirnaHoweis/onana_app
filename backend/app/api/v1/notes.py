import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.note import Note
from app.models.user import User
from app.schemas.notes import NoteCreate, NoteOut, NoteUpdate

router = APIRouter()


def _to_out(note: Note) -> NoteOut:
    return NoteOut(
        id=note.id,
        title=note.title,
        content=note.content,
        voice_url=note.voice_url,
        project_id=note.project_id,
        unit_id=note.unit_id,
        request_id=note.request_id,
        created_by=note.created_by,
        created_at=note.created_at.isoformat(),
    )


@router.get("", response_model=list[NoteOut])
async def list_notes(
    project_id: uuid.UUID | None = Query(None),
    unit_id: uuid.UUID | None = Query(None),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[NoteOut]:
    q = select(Note).where(Note.deleted_at.is_(None))
    if project_id:
        q = q.where(Note.project_id == project_id)
    if unit_id:
        q = q.where(Note.unit_id == unit_id)
    result = await db.execute(q.order_by(Note.created_at.desc()))
    return [_to_out(n) for n in result.scalars().all()]


@router.post("", response_model=NoteOut, status_code=status.HTTP_201_CREATED)
async def create_note(
    body: NoteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> NoteOut:
    note = Note(**body.model_dump(), created_by=current_user.id)
    db.add(note)
    await db.commit()
    await db.refresh(note)
    return _to_out(note)


@router.get("/{note_id}", response_model=NoteOut)
async def get_note(
    note_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> NoteOut:
    result = await db.execute(
        select(Note).where(Note.id == note_id, Note.deleted_at.is_(None))
    )
    note = result.scalar_one_or_none()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return _to_out(note)


@router.patch("/{note_id}", response_model=NoteOut)
async def update_note(
    note_id: uuid.UUID,
    body: NoteUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> NoteOut:
    result = await db.execute(
        select(Note).where(Note.id == note_id, Note.deleted_at.is_(None))
    )
    note = result.scalar_one_or_none()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(note, field, value)
    await db.commit()
    await db.refresh(note)
    return _to_out(note)


@router.delete("/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_note(
    note_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> None:
    result = await db.execute(
        select(Note).where(Note.id == note_id, Note.deleted_at.is_(None))
    )
    note = result.scalar_one_or_none()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    note.deleted_at = datetime.now(timezone.utc)
    await db.commit()
