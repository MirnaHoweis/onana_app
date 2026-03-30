import uuid
from datetime import datetime, timezone
from typing import List


from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.email_draft import EmailDraft
from app.models.user import User
from app.schemas.emails import EmailDraftCreate, EmailDraftUpdate


async def list_drafts(db: AsyncSession, user_id: uuid.UUID) -> List[EmailDraft]:
    result = await db.execute(
        select(EmailDraft)
        .where(EmailDraft.created_by == user_id, EmailDraft.deleted_at.is_(None))
        .order_by(EmailDraft.created_at.desc())
    )
    return list(result.scalars().all())


async def get_draft(
    db: AsyncSession, draft_id: uuid.UUID, user_id: uuid.UUID
) -> EmailDraft | None:
    result = await db.execute(
        select(EmailDraft).where(
            EmailDraft.id == draft_id, EmailDraft.created_by == user_id
        )
    )
    return result.scalar_one_or_none()


async def create_draft(
    db: AsyncSession, payload: EmailDraftCreate, user_id: uuid.UUID
) -> EmailDraft:
    draft = EmailDraft(
        subject=payload.subject,
        body=payload.body,
        recipient_type=payload.recipient_type,
        recipient_email=payload.recipient_email,
        request_id=payload.request_id,
        created_by=user_id,
    )
    db.add(draft)
    await db.commit()
    await db.refresh(draft)
    return draft


async def update_draft(
    db: AsyncSession,
    draft: EmailDraft,
    payload: EmailDraftUpdate,
) -> EmailDraft:
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(draft, field, value)
    await db.commit()
    await db.refresh(draft)
    return draft


async def delete_draft(db: AsyncSession, draft: EmailDraft) -> None:
    draft.deleted_at = datetime.now(timezone.utc)
    await db.commit()


async def send_draft(
    db: AsyncSession,
    draft: EmailDraft,
    to_email_override: str | None = None,
) -> EmailDraft:
    to_email = to_email_override or draft.recipient_email
    if not to_email:
        raise ValueError("No recipient email address provided")

    message = Mail(
        from_email="noreply@presalespro.app",
        to_emails=to_email,
        subject=draft.subject,
        plain_text_content=draft.body,
    )
    sg = SendGridAPIClient(settings.SENDGRID_API_KEY)
    sg.send(message)

    draft.is_sent = True
    draft.sent_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(draft)
    return draft
