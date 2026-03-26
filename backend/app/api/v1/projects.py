import uuid
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.project import Project, ProjectStatus
from app.models.request import Request, RequestStatus
from app.models.unit import Unit, UnitType
from app.models.user import User

router = APIRouter()

# ---------------------------------------------------------------------------
# Schemas (inline — small enough not to warrant a separate file)
# ---------------------------------------------------------------------------

class ProjectCreate(BaseModel):
    name: str
    location: Optional[str] = None
    client_name: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    status: ProjectStatus = ProjectStatus.PLANNING


class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    client_name: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    status: Optional[ProjectStatus] = None


class UnitCreate(BaseModel):
    name: str
    type: UnitType
    floor: Optional[str] = None
    block: Optional[str] = None
    notes: Optional[str] = None


class UnitUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[UnitType] = None
    floor: Optional[str] = None
    block: Optional[str] = None
    notes: Optional[str] = None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_DONE = {RequestStatus.STOREKEEPER_CONFIRMED, RequestStatus.INSTALLATION_COMPLETE}


async def _project_out(project: Project, db: AsyncSession) -> dict:
    unit_count = (await db.execute(
        select(func.count()).select_from(Unit).where(Unit.project_id == project.id)
    )).scalar_one()
    return {
        "id": str(project.id),
        "name": project.name,
        "status": project.status.value,
        "location": project.location,
        "client_name": project.client_name,
        "start_date": project.start_date.isoformat() if project.start_date else None,
        "end_date": project.end_date.isoformat() if project.end_date else None,
        "unit_count": unit_count,
        "created_at": project.created_at.isoformat(),
    }


async def _unit_out(unit: Unit, db: AsyncSession) -> dict:
    # Derive current stage from latest non-complete request
    req_result = await db.execute(
        select(Request)
        .where(Request.unit_id == unit.id)
        .order_by(Request.created_at.desc())
        .limit(1)
    )
    latest_req = req_result.scalar_one_or_none()

    active_count = (await db.execute(
        select(func.count()).select_from(Request).where(
            Request.unit_id == unit.id,
            Request.status.notin_(_DONE),
        )
    )).scalar_one()

    return {
        "id": str(unit.id),
        "project_id": str(unit.project_id),
        "name": unit.name,
        "type": unit.type.value,
        "floor": unit.floor,
        "block": unit.block,
        "notes": unit.notes,
        "active_request_count": active_count,
        "current_stage": latest_req.status.value if latest_req else None,
        "created_at": unit.created_at.isoformat(),
    }


# ---------------------------------------------------------------------------
# Projects
# ---------------------------------------------------------------------------

@router.get("")
async def list_projects(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Project)
        .where(Project.deleted_at.is_(None))
        .order_by(Project.created_at.desc())
    )
    projects = result.scalars().all()
    return [await _project_out(p, db) for p in projects]


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_project(
    body: ProjectCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    project = Project(**body.model_dump(), created_by=current_user.id)
    db.add(project)
    await db.commit()
    await db.refresh(project)
    return await _project_out(project, db)


@router.get("/{project_id}")
async def get_project(
    project_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return await _project_out(project, db)


@router.patch("/{project_id}")
async def update_project(
    project_id: uuid.UUID,
    body: ProjectUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(project, field, value)
    await db.commit()
    await db.refresh(project)
    return await _project_out(project, db)


@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_project(
    project_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime, timezone
    result = await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    project.deleted_at = datetime.now(timezone.utc)
    await db.commit()


# ---------------------------------------------------------------------------
# Units (nested under project)
# ---------------------------------------------------------------------------

@router.get("/{project_id}/units")
async def list_units(
    project_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Unit)
        .where(Unit.project_id == project_id)
        .order_by(Unit.created_at.asc())
    )
    units = result.scalars().all()
    return [await _unit_out(u, db) for u in units]


@router.post("/{project_id}/units", status_code=status.HTTP_201_CREATED)
async def create_unit(
    project_id: uuid.UUID,
    body: UnitCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    project_exists = (await db.execute(
        select(Project.id).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not project_exists:
        raise HTTPException(status_code=404, detail="Project not found")
    unit = Unit(**body.model_dump(), project_id=project_id)
    db.add(unit)
    await db.commit()
    await db.refresh(unit)
    return await _unit_out(unit, db)


@router.get("/{project_id}/units/{unit_id}")
async def get_unit(
    project_id: uuid.UUID,
    unit_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Unit).where(Unit.id == unit_id, Unit.project_id == project_id)
    )
    unit = result.scalar_one_or_none()
    if not unit:
        raise HTTPException(status_code=404, detail="Unit not found")
    return await _unit_out(unit, db)


@router.get("/{project_id}/dashboard")
async def project_dashboard(
    project_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """All data needed for the project dashboard in one request."""
    from app.models.installation import Installation
    from app.models.note import Note
    from app.models.email_draft import EmailDraft

    result = await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # All units for this project
    unit_result = await db.execute(select(Unit).where(Unit.project_id == project_id))
    units = unit_result.scalars().all()
    unit_ids = [u.id for u in units]

    # All requests through units
    requests = []
    if unit_ids:
        req_result = await db.execute(
            select(Request)
            .where(Request.unit_id.in_(unit_ids))
            .order_by(Request.created_at.desc())
        )
        requests = req_result.scalars().all()

    request_ids = [r.id for r in requests]

    # Group requests by status
    status_counts: dict[str, int] = {}
    for r in requests:
        key = r.status.value
        status_counts[key] = status_counts.get(key, 0) + 1

    # Installations through requests
    installations = []
    if request_ids:
        inst_result = await db.execute(
            select(Installation)
            .where(Installation.request_id.in_(request_ids))
            .order_by(Installation.start_date.desc().nullslast())
        )
        installations = inst_result.scalars().all()

    avg_completion = (
        int(sum(i.completion_percentage for i in installations) / len(installations))
        if installations else 0
    )

    # Notes for this project
    note_result = await db.execute(
        select(Note)
        .where(Note.project_id == project_id, Note.deleted_at.is_(None))
        .order_by(Note.created_at.desc())
        .limit(10)
    )
    notes = note_result.scalars().all()

    # Email drafts linked to this project's requests
    emails = []
    if request_ids:
        email_result = await db.execute(
            select(EmailDraft)
            .where(EmailDraft.request_id.in_(request_ids))
            .order_by(EmailDraft.created_at.desc())
            .limit(10)
        )
        emails = email_result.scalars().all()

    return {
        "project": await _project_out(project, db),
        "stats": {
            "requests_total": len(requests),
            "requests_by_status": status_counts,
            "installations_count": len(installations),
            "installations_avg_completion": avg_completion,
            "notes_count": len(notes),
            "emails_count": len(emails),
        },
        "requests": [
            {
                "id": str(r.id),
                "title": r.title,
                "status": r.status.value,
                "priority": r.priority.value,
                "category": r.category.value,
                "unit_id": str(r.unit_id),
                "created_at": r.created_at.isoformat(),
            }
            for r in requests
        ],
        "installations": [
            {
                "id": str(i.id),
                "request_id": str(i.request_id),
                "completion_percentage": i.completion_percentage,
                "start_date": i.start_date.isoformat() if i.start_date else None,
                "estimated_end_date": i.estimated_end_date.isoformat() if i.estimated_end_date else None,
                "is_partial": i.is_partial,
            }
            for i in installations
        ],
        "notes": [
            {
                "id": str(n.id),
                "title": n.title,
                "content": n.content,
                "created_at": n.created_at.isoformat(),
            }
            for n in notes
        ],
        "emails": [
            {
                "id": str(e.id),
                "subject": e.subject,
                "recipient_type": e.recipient_type.value if e.recipient_type else None,
                "recipient_email": e.recipient_email,
                "is_sent": e.is_sent,
                "created_at": e.created_at.isoformat(),
            }
            for e in emails
        ],
    }


@router.patch("/{project_id}/units/{unit_id}")
async def update_unit(
    project_id: uuid.UUID,
    unit_id: uuid.UUID,
    body: UnitUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Unit).where(Unit.id == unit_id, Unit.project_id == project_id)
    )
    unit = result.scalar_one_or_none()
    if not unit:
        raise HTTPException(status_code=404, detail="Unit not found")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(unit, field, value)
    await db.commit()
    await db.refresh(unit)
    return await _unit_out(unit, db)
