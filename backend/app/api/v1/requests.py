import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.request import Request, RequestStatus
from app.models.request_history import RequestHistory
from app.models.user import User
from app.schemas.requests import (
    RequestCreate,
    RequestOut,
    RequestUpdate,
    StatusUpdateRequest,
)

router = APIRouter()


@router.get("", response_model=list[RequestOut])
async def list_requests(
    unit_id: uuid.UUID | None = Query(None),
    status: RequestStatus | None = Query(None),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[Request]:
    q = select(Request).where(Request.deleted_at.is_(None))
    if unit_id:
        q = q.where(Request.unit_id == unit_id)
    if status:
        q = q.where(Request.status == status)
    result = await db.execute(q.order_by(Request.created_at.desc()))
    return list(result.scalars().all())


@router.post("", response_model=RequestOut, status_code=status.HTTP_201_CREATED)
async def create_request(
    body: RequestCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Request:
    req = Request(**body.model_dump(), created_by=current_user.id)
    db.add(req)
    await db.commit()
    await db.refresh(req)
    return req


@router.get("/{request_id}", response_model=RequestOut)
async def get_request(
    request_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Request:
    result = await db.execute(
        select(Request).where(Request.id == request_id)
    )
    req = result.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    return req


@router.patch("/{request_id}", response_model=RequestOut)
async def update_request(
    request_id: uuid.UUID,
    body: RequestUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Request:
    result = await db.execute(
        select(Request).where(Request.id == request_id)
    )
    req = result.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")

    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(req, field, value)

    await db.commit()
    await db.refresh(req)
    return req


@router.post("/{request_id}/status", response_model=RequestOut)
async def update_status(
    request_id: uuid.UUID,
    body: StatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Request:
    result = await db.execute(
        select(Request).where(Request.id == request_id)
    )
    req = result.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")

    history = RequestHistory(
        request_id=req.id,
        from_status=req.status.value,
        to_status=body.status.value,
        changed_by=current_user.id,
        notes=body.notes,
    )
    db.add(history)
    req.status = body.status
    await db.commit()
    await db.refresh(req)
    return req


@router.delete("/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_request(
    request_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> None:
    result = await db.execute(
        select(Request).where(Request.id == request_id, Request.deleted_at.is_(None))
    )
    req = result.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    req.deleted_at = datetime.now(timezone.utc)
    await db.commit()
