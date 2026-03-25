# Import all models so SQLAlchemy registers them with Base.metadata
from app.models.user import User  # noqa: F401
from app.models.project import Project  # noqa: F401
from app.models.unit import Unit  # noqa: F401
from app.models.request import Request  # noqa: F401
from app.models.request_history import RequestHistory  # noqa: F401
from app.models.installation import Installation, InstallationItem  # noqa: F401
from app.models.note import Note  # noqa: F401
from app.models.email_draft import EmailDraft  # noqa: F401
