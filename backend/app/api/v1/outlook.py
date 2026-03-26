import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.outlook_token import OutlookToken
from app.models.user import User
from app.services import outlook_service

router = APIRouter()


class SendViaOutlookRequest(BaseModel):
    to_email: str
    subject: str
    body: str


@router.get("/auth-url")
async def get_auth_url(current_user: User = Depends(get_current_user)):
    """Returns the Microsoft OAuth URL. Open this in a browser to connect Outlook."""
    try:
        state = str(current_user.id)
        url = outlook_service.get_auth_url(state)
        return {"auth_url": url}
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e))


@router.get("/callback")
async def oauth_callback(
    code: str = Query(...),
    state: str = Query(...),
    db: AsyncSession = Depends(get_db),
):
    """
    Microsoft redirects here after the user grants consent.
    The `state` parameter is the user's UUID.
    """
    try:
        user_id = uuid.UUID(state)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid state parameter")

    try:
        token_data = await outlook_service.exchange_code(code)
        await outlook_service.save_token(db, user_id, token_data)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Token exchange failed: {e}")

    # Redirect back to the app after successful connection
    return RedirectResponse(url="http://localhost:8080/#/settings?outlook=connected")


@router.get("/status")
async def outlook_status(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Check whether the current user has Outlook connected."""
    result = await db.execute(
        select(OutlookToken).where(OutlookToken.user_id == current_user.id)
    )
    record = result.scalar_one_or_none()
    if not record:
        return {"connected": False, "email": None}
    return {"connected": True, "email": record.email}


@router.delete("/disconnect")
async def disconnect_outlook(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Remove stored Outlook tokens for the current user."""
    result = await db.execute(
        select(OutlookToken).where(OutlookToken.user_id == current_user.id)
    )
    record = result.scalar_one_or_none()
    if record:
        await db.delete(record)
        await db.commit()
    return {"disconnected": True}


@router.post("/send")
async def send_via_outlook(
    payload: SendViaOutlookRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Send an email through the user's connected Outlook account."""
    access_token = await outlook_service.get_valid_token(db, current_user.id)
    if not access_token:
        raise HTTPException(
            status_code=403,
            detail="Outlook not connected. Connect your account in Settings first.",
        )
    try:
        await outlook_service.send_email(
            access_token, payload.to_email, payload.subject, payload.body
        )
        return {"sent": True}
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Failed to send via Outlook: {e}")
