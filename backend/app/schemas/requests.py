import uuid
from datetime import date, datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel

from app.models.request import RequestCategory, RequestPriority, RequestStatus


class RequestCreate(BaseModel):
    unit_id: uuid.UUID
    title: str
    description: Optional[str] = None
    category: RequestCategory
    priority: RequestPriority = RequestPriority.MEDIUM
    supplier_name: Optional[str] = None


class RequestUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[RequestCategory] = None
    priority: Optional[RequestPriority] = None
    supplier_name: Optional[str] = None
    po_number: Optional[str] = None
    po_date: Optional[date] = None
    expected_delivery_date: Optional[date] = None
    actual_delivery_date: Optional[date] = None
    assigned_to: Optional[uuid.UUID] = None


class StatusUpdateRequest(BaseModel):
    status: RequestStatus
    notes: Optional[str] = None


class RequestOut(BaseModel):
    id: uuid.UUID
    unit_id: uuid.UUID
    title: str
    description: Optional[str]
    category: RequestCategory
    status: RequestStatus
    priority: RequestPriority
    supplier_name: Optional[str]
    po_number: Optional[str]
    po_date: Optional[date]
    expected_delivery_date: Optional[date]
    actual_delivery_date: Optional[date]
    assigned_to: Optional[uuid.UUID]
    created_by: uuid.UUID
    created_at: datetime

    model_config = {"from_attributes": True}
