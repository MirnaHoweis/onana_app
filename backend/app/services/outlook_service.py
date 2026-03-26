"""
Microsoft Outlook integration via Microsoft Graph API (OAuth2).

Setup steps (one-time, by admin):
1. Go to https://portal.azure.com → Azure Active Directory → App registrations → New registration
2. Name: PreSales Pro
3. Supported account types: "Accounts in any organizational directory and personal Microsoft accounts"
4. Redirect URI: Web → http://localhost:8000/api/v1/outlook/callback
5. After creation, copy Application (client) ID → MICROSOFT_CLIENT_ID in .env
6. Certificates & secrets → New client secret → copy value → MICROSOFT_CLIENT_SECRET in .env
7. API permissions → Add permission → Microsoft Graph → Delegated:
   - Mail.Send, Mail.ReadWrite, User.Read → Grant admin consent
"""
import uuid
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.outlook_token import OutlookToken

_AUTHORITY = "https://login.microsoftonline.com"
_GRAPH = "https://graph.microsoft.com/v1.0"
_SCOPES = "https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/Mail.ReadWrite https://graph.microsoft.com/User.Read offline_access"


def get_auth_url(state: str) -> str:
    """Build the Microsoft OAuth2 authorization URL to redirect the user to."""
    if not settings.MICROSOFT_CLIENT_ID:
        raise ValueError("MICROSOFT_CLIENT_ID not configured in .env")
    params = {
        "client_id": settings.MICROSOFT_CLIENT_ID,
        "response_type": "code",
        "redirect_uri": settings.MICROSOFT_REDIRECT_URI,
        "response_mode": "query",
        "scope": _SCOPES,
        "state": state,
    }
    return f"{_AUTHORITY}/{settings.MICROSOFT_TENANT_ID}/oauth2/v2.0/authorize?{urlencode(params)}"


async def exchange_code(code: str) -> dict:
    """Exchange authorization code for access + refresh tokens."""
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{_AUTHORITY}/{settings.MICROSOFT_TENANT_ID}/oauth2/v2.0/token",
            data={
                "client_id": settings.MICROSOFT_CLIENT_ID,
                "client_secret": settings.MICROSOFT_CLIENT_SECRET,
                "code": code,
                "redirect_uri": settings.MICROSOFT_REDIRECT_URI,
                "grant_type": "authorization_code",
                "scope": _SCOPES,
            },
        )
        resp.raise_for_status()
        return resp.json()


async def refresh_token(refresh_tok: str) -> dict:
    """Get a new access token using a stored refresh token."""
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{_AUTHORITY}/{settings.MICROSOFT_TENANT_ID}/oauth2/v2.0/token",
            data={
                "client_id": settings.MICROSOFT_CLIENT_ID,
                "client_secret": settings.MICROSOFT_CLIENT_SECRET,
                "refresh_token": refresh_tok,
                "grant_type": "refresh_token",
                "scope": _SCOPES,
            },
        )
        resp.raise_for_status()
        return resp.json()


async def get_user_email(access_token: str) -> str:
    """Fetch the signed-in user's email from Graph API."""
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{_GRAPH}/me",
            headers={"Authorization": f"Bearer {access_token}"},
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("mail") or data.get("userPrincipalName", "")


async def save_token(db: AsyncSession, user_id: uuid.UUID, token_data: dict) -> OutlookToken:
    """Persist or update an OutlookToken for the given user."""
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=token_data.get("expires_in", 3600))
    access_tok = token_data["access_token"]
    refresh_tok = token_data.get("refresh_token", "")

    outlook_email = await get_user_email(access_tok)

    result = await db.execute(
        select(OutlookToken).where(OutlookToken.user_id == user_id)
    )
    record = result.scalar_one_or_none()
    if record:
        record.access_token = access_tok
        record.refresh_token = refresh_tok
        record.expires_at = expires_at
        record.email = outlook_email
    else:
        record = OutlookToken(
            user_id=user_id,
            access_token=access_tok,
            refresh_token=refresh_tok,
            expires_at=expires_at,
            email=outlook_email,
        )
        db.add(record)

    await db.commit()
    await db.refresh(record)
    return record


async def get_valid_token(db: AsyncSession, user_id: uuid.UUID) -> str | None:
    """Return a valid access token, refreshing if needed. Returns None if not connected."""
    result = await db.execute(
        select(OutlookToken).where(OutlookToken.user_id == user_id)
    )
    record = result.scalar_one_or_none()
    if not record:
        return None

    # Refresh if expired (with 60s buffer)
    if record.expires_at <= datetime.now(timezone.utc) + timedelta(seconds=60):
        try:
            token_data = await refresh_token(record.refresh_token)
            record = await save_token(db, user_id, token_data)
        except Exception:
            return None

    return record.access_token


async def send_email(
    access_token: str,
    to_email: str,
    subject: str,
    body: str,
) -> None:
    """Send an email via Microsoft Graph API."""
    payload = {
        "message": {
            "subject": subject,
            "body": {"contentType": "Text", "content": body},
            "toRecipients": [{"emailAddress": {"address": to_email}}],
        },
        "saveToSentItems": "true",
    }
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{_GRAPH}/me/sendMail",
            json=payload,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            },
        )
        resp.raise_for_status()
