from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.services import import_service

router = APIRouter()

_MAX_SIZE = 10 * 1024 * 1024  # 10 MB


@router.post("/excel")
async def import_excel(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Import Projects and/or Requests from an Excel file.

    The workbook must contain sheets named **"Projects"** and/or **"Requests"**.

    **Projects sheet columns:**
    `Name` | `Client Name` | `Location` | `Status` | `Start Date` | `End Date`

    **Requests sheet columns:**
    `Project Name` | `Unit Name` | `Unit Type` | `Title` | `Category` |
    `Priority` | `Description` | `Supplier` | `Expected Delivery`

    Status values: PLANNING, ACTIVE, ON_HOLD, COMPLETED
    Category values: FURNITURE, APPLIANCE, FINISHING, OTHER
    Priority values: LOW, MEDIUM, HIGH, URGENT
    Unit Type values: VILLA, APARTMENT, COMMERCIAL
    Date format: YYYY-MM-DD
    """
    if not file.filename or not file.filename.endswith((".xlsx", ".xlsm")):
        raise HTTPException(status_code=400, detail="Only .xlsx / .xlsm files are accepted")

    content = await file.read()
    if len(content) > _MAX_SIZE:
        raise HTTPException(status_code=413, detail="File too large (max 10 MB)")

    summary = await import_service.import_excel(db, content, current_user.id)
    return summary


@router.get("/template-info")
async def template_info():
    """Return the expected column structure for the import template."""
    return {
        "sheets": {
            "Projects": {
                "columns": ["Name*", "Client Name", "Location", "Status", "Start Date", "End Date"],
                "notes": "Status: PLANNING | ACTIVE | ON_HOLD | COMPLETED. Dates: YYYY-MM-DD.",
            },
            "Requests": {
                "columns": [
                    "Project Name*", "Unit Name*", "Unit Type", "Title*",
                    "Category", "Priority", "Description", "Supplier", "Expected Delivery",
                ],
                "notes": (
                    "Project must already exist. Unit is auto-created if not found. "
                    "Category: FURNITURE | APPLIANCE | FINISHING | OTHER. "
                    "Priority: LOW | MEDIUM | HIGH | URGENT. "
                    "Unit Type: VILLA | APARTMENT | COMMERCIAL."
                ),
            },
        }
    }
