from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.installation import Installation
from app.models.project import Project, ProjectStatus
from app.models.request import Request, RequestStatus
from app.models.unit import Unit
from app.models.user import User

router = APIRouter()


@router.get("/stats")
async def dashboard_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    done = {RequestStatus.STOREKEEPER_CONFIRMED, RequestStatus.INSTALLATION_COMPLETE}

    # Counts
    total_projects = (await db.execute(
        select(func.count()).select_from(Project).where(Project.deleted_at.is_(None))
    )).scalar_one()

    active_projects = (await db.execute(
        select(func.count()).select_from(Project).where(
            Project.status == ProjectStatus.ACTIVE,
            Project.deleted_at.is_(None),
        )
    )).scalar_one()

    pending_requests = (await db.execute(
        select(func.count()).select_from(Request).where(
            Request.status.notin_(done)
        )
    )).scalar_one()

    overdue_items = (await db.execute(
        select(func.count()).select_from(Request).where(
            Request.status.notin_(done),
            Request.expected_delivery_date.isnot(None),
            Request.expected_delivery_date < today,
        )
    )).scalar_one()

    installations_in_progress = (await db.execute(
        select(func.count()).select_from(Installation).where(
            Installation.completion_percentage < 100
        )
    )).scalar_one()

    # Pending actions: oldest non-complete requests (up to 10)
    pending_result = await db.execute(
        select(Request, Unit, Project)
        .join(Unit, Request.unit_id == Unit.id)
        .join(Project, Unit.project_id == Project.id)
        .where(Request.status.notin_(done))
        .order_by(Request.created_at.asc())
        .limit(10)
    )
    pending_actions = []
    for req, unit, project in pending_result.tuples():
        days_overdue = 0
        if req.expected_delivery_date and req.expected_delivery_date < today:
            days_overdue = (today - req.expected_delivery_date).days
        pending_actions.append({
            "id": str(req.id),
            "title": req.title,
            "subtitle": f"{req.status.value.replace('_', ' ').title()} — {unit.name}",
            "project_name": project.name,
            "days_overdue": days_overdue,
        })

    # Delay alerts: overdue requests
    delay_result = await db.execute(
        select(Request, Unit, Project)
        .join(Unit, Request.unit_id == Unit.id)
        .join(Project, Unit.project_id == Project.id)
        .where(
            Request.status.notin_(done),
            Request.expected_delivery_date.isnot(None),
            Request.expected_delivery_date < today,
        )
        .order_by(Request.expected_delivery_date.asc())
        .limit(5)
    )
    delay_alerts = []
    for req, unit, project in delay_result.tuples():
        delay_alerts.append({
            "id": str(req.id),
            "title": req.title,
            "project_name": project.name,
            "days_late": (today - req.expected_delivery_date).days,
            "stage": req.status.value,
        })

    return {
        "total_projects": total_projects,
        "active_projects": active_projects,
        "pending_requests": pending_requests,
        "overdue_items": overdue_items,
        "installations_in_progress": installations_in_progress,
        "pending_actions": pending_actions,
        "delay_alerts": delay_alerts,
    }
