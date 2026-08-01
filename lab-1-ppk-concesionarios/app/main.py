from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware

from config import settings
from database import SessionLocal, init_db
from routers import documents, download, pages
from seed import seed_data

app = FastAPI(title="PPK Concesionarios - Portal de gestión")

app.add_middleware(SessionMiddleware, secret_key=settings.SECRET_KEY)
app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(pages.router)
app.include_router(download.router)
app.include_router(documents.router)


@app.on_event("startup")
def on_startup() -> None:
    init_db()
    db = SessionLocal()
    try:
        seed_data(db)
    finally:
        db.close()
