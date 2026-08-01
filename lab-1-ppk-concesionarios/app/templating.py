from fastapi import Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from config import settings

templates = Jinja2Templates(directory="templates")


def render(request: Request, template_name: str, **context) -> HTMLResponse:
    ctx = {
        "request": request,
        "app_mode": settings.APP_MODE,
        "is_dev": settings.is_dev,
        "version_label": settings.version_label,
        "current_user": request.session.get("username"),
        **context,
    }
    return templates.TemplateResponse(template_name, ctx)
