import uuid
from datetime import date
from typing import Optional

from pydantic import BaseModel, Field


class InstallationCreate(BaseModel):
    request_id: uuid.UUID
    start_date: Optional[date] = None
    estimated_end_date: Optional[date] = None
    notes: Optional[str] = None


class InstallationUpdate(BaseModel):
    completion_percentage: Optional[int] = Field(None, ge=0, le=100)
    start_date: Optional[date] = None
    estimated_end_date: Optional[date] = None
    actual_end_date: Optional[date] = None
    is_partial: Optional[bool] = None
    notes: Optional[str] = None


class InstallationItemCreate(BaseModel):
    item_name: str
    sort_order: int = 0


class ItemToggle(BaseModel):
    is_completed: bool


class InstallationItemOut(BaseModel):
    id: uuid.UUID
    installation_id: uuid.UUID
    item_name: str
    is_completed: bool
    sort_order: int
    completed_at: Optional[str]
    completed_by: Optional[uuid.UUID]

    model_config = {"from_attributes": True}


class InstallationOut(BaseModel):
    id: uuid.UUID
    request_id: uuid.UUID
    completion_percentage: int
    is_partial: bool
    start_date: Optional[date]
    estimated_end_date: Optional[date]
    actual_end_date: Optional[date]
    notes: Optional[str]
    items: list[InstallationItemOut] = []

    model_config = {"from_attributes": True}
