"""
AI service — wraps the Anthropic Claude API for pre-sales workflow intelligence.
All calls use claude-sonnet-4-20250514.
"""
import uuid
from datetime import date, datetime, timezone
from typing import List

import anthropic
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.request import Request, RequestStatus
from app.schemas.ai import (
    DailySummaryResponse,
    DelayAlert,
    DetectDelaysResponse,
    ExtractedTask,
    NoteToTaskResponse,
    SuggestedAction,
    SuggestActionsResponse,
)


def _client() -> anthropic.AsyncAnthropic:
    if not settings.ANTHROPIC_API_KEY:
        raise ValueError("ANTHROPIC_API_KEY_NOT_SET")
    return anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)


def _today() -> str:
    return date.today().isoformat()


# ---------------------------------------------------------------------------
# suggest-actions
# ---------------------------------------------------------------------------

async def suggest_actions(
    db: AsyncSession, request_id: uuid.UUID, extra_context: str | None
) -> SuggestActionsResponse:
    result = await db.execute(select(Request).where(Request.id == request_id))
    req = result.scalar_one_or_none()
    if req is None:
        return SuggestActionsResponse(request_id=request_id, actions=[])

    context_block = f"\nAdditional context: {extra_context}" if extra_context else ""
    prompt = f"""You are a pre-sales engineering workflow assistant.

Request details:
- Title: {req.title}
- Category: {req.category.value}
- Current stage: {req.status.value}
- Priority: {req.priority.value}
- Supplier: {req.supplier_name or 'not specified'}
- PO number: {req.po_number or 'not issued'}
- Expected delivery: {req.expected_delivery_date or 'not set'}
- Actual delivery: {req.actual_delivery_date or 'not yet'}
- Today: {_today()}
{context_block}

Return a JSON array of up to 5 suggested next actions. Each item must have:
  "action": short imperative sentence
  "reason": one sentence explaining why
  "priority": one of "high", "medium", "low"

Respond with ONLY valid JSON — no markdown, no commentary."""

    client = _client()
    message = await client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=512,
        messages=[{"role": "user", "content": prompt}],
    )
    import json
    raw = message.content[0].text.strip()
    items = json.loads(raw)
    actions = [SuggestedAction(**item) for item in items]
    return SuggestActionsResponse(request_id=request_id, actions=actions)


# ---------------------------------------------------------------------------
# detect-delays
# ---------------------------------------------------------------------------

async def detect_delays(
    db: AsyncSession, user_id: uuid.UUID, project_id: uuid.UUID | None
) -> DetectDelaysResponse:
    query = select(Request).where(
        Request.created_by == user_id,
        Request.status.notin_([
            RequestStatus.STOREKEEPER_CONFIRMED,
            RequestStatus.INSTALLATION_COMPLETE,
        ]),
        Request.expected_delivery_date.isnot(None),
    )
    result = await db.execute(query)
    requests = result.scalars().all()

    today = date.today()
    overdue = [r for r in requests if r.expected_delivery_date < today]

    if not overdue:
        return DetectDelaysResponse(alerts=[])

    lines = "\n".join(
        f"- id={r.id} title={r.title!r} stage={r.status.value} "
        f"expected={r.expected_delivery_date} days_overdue={(today - r.expected_delivery_date).days}"
        for r in overdue
    )

    prompt = f"""You are a pre-sales workflow assistant detecting delivery delays.

Today: {_today()}
Overdue requests:
{lines}

For each request, provide a brief recommendation (one sentence).
Return a JSON array where each item has:
  "request_id": the UUID string
  "title": request title
  "stage": current stage
  "days_overdue": integer
  "recommendation": one-sentence action recommendation

Respond with ONLY valid JSON."""

    client = _client()
    message = await client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=768,
        messages=[{"role": "user", "content": prompt}],
    )
    import json
    raw = message.content[0].text.strip()
    items = json.loads(raw)
    alerts = [DelayAlert(**item) for item in items]
    return DetectDelaysResponse(alerts=alerts)


# ---------------------------------------------------------------------------
# daily-summary
# ---------------------------------------------------------------------------

async def daily_summary(
    db: AsyncSession, user_id: uuid.UUID
) -> DailySummaryResponse:
    result = await db.execute(
        select(Request).where(Request.created_by == user_id)
    )
    all_requests = result.scalars().all()

    total = len(all_requests)
    done_statuses = {RequestStatus.STOREKEEPER_CONFIRMED, RequestStatus.INSTALLATION_COMPLETE}
    pending = [r for r in all_requests if r.status not in done_statuses]
    today = date.today()
    overdue = [
        r for r in pending
        if r.expected_delivery_date and r.expected_delivery_date < today
    ]

    stage_counts: dict[str, int] = {}
    for r in all_requests:
        stage_counts[r.status.value] = stage_counts.get(r.status.value, 0) + 1

    stage_summary = ", ".join(f"{k}:{v}" for k, v in stage_counts.items())

    prompt = f"""You are a pre-sales engineering workflow assistant generating a daily briefing.

Today: {_today()}
Total requests: {total}
Pending (not completed): {len(pending)}
Overdue: {len(overdue)}
Stage breakdown: {stage_summary}

Write a concise daily summary (2-3 sentences) and 3-5 highlight bullet points.
Return JSON with:
  "summary": string
  "highlights": array of strings
  "pending_count": integer
  "overdue_count": integer

Respond with ONLY valid JSON."""

    client = _client()
    message = await client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=512,
        messages=[{"role": "user", "content": prompt}],
    )
    import json
    raw = message.content[0].text.strip()
    data = json.loads(raw)
    # Ensure counts are from DB, not hallucinated
    data["pending_count"] = len(pending)
    data["overdue_count"] = len(overdue)
    return DailySummaryResponse(**data)


# ---------------------------------------------------------------------------
# note-to-task
# ---------------------------------------------------------------------------

async def note_to_task(note_text: str) -> NoteToTaskResponse:
    prompt = f"""You are a pre-sales engineering workflow assistant.

Extract actionable tasks from the following note:
---
{note_text}
---

Return a JSON array of tasks. Each item must have:
  "title": short task title (max 80 chars)
  "description": one sentence elaboration
  "priority": one of "high", "medium", "low"
  "due_hint": optional string like "by end of week", null if not mentioned

Respond with ONLY valid JSON — no markdown, no commentary."""

    client = _client()
    message = await client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=512,
        messages=[{"role": "user", "content": prompt}],
    )
    import json
    raw = message.content[0].text.strip()
    items = json.loads(raw)
    tasks = [ExtractedTask(**item) for item in items]
    return NoteToTaskResponse(tasks=tasks)
