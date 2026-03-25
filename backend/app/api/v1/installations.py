import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.installation import Installation, InstallationItem
from app.models.user import User
from app.schemas.installations import (
    InstallationCreate,
    InstallationItemCreate,
    InstallationOut,
    InstallationUpdate,
    ItemToggle,
)

router = APIRouter()


async def _get_installation(
    installation_id: uuid.UUID, db: AsyncSession
) -> Installation:
    result = await db.execute(
        select(Installation)
        .where(Installation.id == installation_id)
        .options(selectinload(Installation.items))
    )
    inst = result.scalar_one_or_none()
    if not inst:
        raise HTTPException(status_code=404, detail="Installation not found")
    return inst


@router.get("", response_model=list[InstallationOut])
async def list_installations(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[Installation]:
    result = await db.execute(
        select(Installation).options(selectinload(Installation.items))
    )
    return list(result.scalars().all())


@router.post("", response_model=InstallationOut, status_code=status.HTTP_201_CREATED)
async def create_installation(
    body: InstallationCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Installation:
    inst = Installation(**body.model_dump())
    db.add(inst)
    await db.commit()
    await db.refresh(inst)
    return inst


@router.get("/{installation_id}", response_model=InstallationOut)
async def get_installation(
    installation_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Installation:
    return await _get_installation(installation_id, db)


@router.patch("/{installation_id}", response_model=InstallationOut)
async def update_installation(
    installation_id: uuid.UUID,
    body: InstallationUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Installation:
    inst = await _get_installation(installation_id, db)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(inst, field, value)
    await db.commit()
    await db.refresh(inst)
    return inst


@router.post("/{installation_id}/items", response_model=InstallationOut)
async def add_checklist_item(
    installation_id: uuid.UUID,
    body: InstallationItemCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Installation:
    inst = await _get_installation(installation_id, db)
    item = InstallationItem(
        installation_id=inst.id,
        item_name=body.item_name,
        sort_order=body.sort_order,
    )
    db.add(item)
    await db.commit()
    return await _get_installation(installation_id, db)


@router.patch("/{installation_id}/items/{item_id}", response_model=InstallationOut)
async def toggle_checklist_item(
    installation_id: uuid.UUID,
    item_id: uuid.UUID,
    body: ItemToggle,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Installation:
    result = await db.execute(
        select(InstallationItem).where(InstallationItem.id == item_id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    item.is_completed = body.is_completed
    item.completed_at = (
        datetime.now(timezone.utc) if body.is_completed else None
    )
    item.completed_by = current_user.id if body.is_completed else None

    # Recalculate completion percentage
    inst = await _get_installation(installation_id, db)
    total = len(inst.items)
    if total > 0:
        completed = sum(1 for i in inst.items if i.is_completed)
        # Count the current item toggle
        if item.id not in [i.id for i in inst.items]:
            completed = completed + (1 if body.is_completed else -1)
        inst.completion_percentage = round(completed / total * 100)

    await db.commit()
    return await _get_installation(installation_id, db)
