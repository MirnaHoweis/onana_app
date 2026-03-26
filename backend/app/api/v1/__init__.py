from fastapi import APIRouter

from app.api.v1.auth import router as auth_router
from app.api.v1.dashboard import router as dashboard_router
from app.api.v1.projects import router as projects_router
from app.api.v1.requests import router as requests_router
from app.api.v1.installations import router as installations_router
from app.api.v1.notes import router as notes_router
from app.api.v1.emails import router as emails_router
from app.api.v1.ai import router as ai_router
from app.api.v1.import_data import router as import_router
from app.api.v1.outlook import router as outlook_router

router = APIRouter()
router.include_router(auth_router, prefix="/auth", tags=["auth"])
router.include_router(dashboard_router, prefix="/dashboard", tags=["dashboard"])
router.include_router(projects_router, prefix="/projects", tags=["projects"])
router.include_router(requests_router, prefix="/requests", tags=["requests"])
router.include_router(installations_router, prefix="/installations", tags=["installations"])
router.include_router(notes_router, prefix="/notes", tags=["notes"])
router.include_router(emails_router, prefix="/email", tags=["email"])
router.include_router(ai_router, prefix="/ai", tags=["ai"])
router.include_router(import_router, prefix="/import", tags=["import"])
router.include_router(outlook_router, prefix="/outlook", tags=["outlook"])
