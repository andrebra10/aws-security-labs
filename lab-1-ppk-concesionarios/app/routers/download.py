import os

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from config import settings

router = APIRouter()

# Local manuals/guides shipped with the app, meant to be served by /download.
FILES_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "files")

# Only used in production: an explicit allowlist, so a filename can never
# resolve outside FILES_DIR no matter what a caller sends.
ALLOWED_FILES = {"manual.pdf", "financing_guide.pdf"}


@router.get("/download")
def download_file(file: str):
    if settings.is_dev:
        # Development shortcut: written for a quick internal demo and never
        # revisited. It trusts the "file" query param and joins it straight
        # onto the manuals directory, so "../" sequences walk right out of
        # it - textbook local file inclusion.
        target_path = os.path.join(FILES_DIR, file)
        if not os.path.isfile(target_path):
            raise HTTPException(status_code=404, detail="Archivo no encontrado")
        return FileResponse(target_path)

    # Production: only a fixed, known-safe filename can ever be served.
    filename = os.path.basename(file)
    if filename not in ALLOWED_FILES:
        raise HTTPException(status_code=404, detail="Archivo no encontrado")
    target_path = os.path.join(FILES_DIR, filename)
    if not os.path.isfile(target_path):
        raise HTTPException(status_code=404, detail="Archivo no encontrado")
    return FileResponse(target_path)
