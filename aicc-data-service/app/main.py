import logging
from contextlib import asynccontextmanager

from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles

from app.routers import (
    admin,
    catalog,
    chat,
    courses,
    docs_pages,
    documents,
    notifications,
    stats,
    students,
)

log = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        from app.embeddings import warm_handbook
        from app.handbook import HANDBOOK_PATH, load_entries

        warm_handbook(list(load_entries()), HANDBOOK_PATH.stat().st_mtime_ns)
    except Exception:
        log.exception("Handbook embeddings were not started.")
    yield


app = FastAPI(title="AICC Dummy Data Service", version="0.4.0", lifespan=lifespan)

app.include_router(admin.router, prefix="/api")
app.include_router(catalog.router, prefix="/api")
app.include_router(students.router, prefix="/api")
app.include_router(stats.router, prefix="/api")
app.include_router(courses.router, prefix="/api")
app.include_router(notifications.router, prefix="/api")
app.include_router(documents.router, prefix="/api")
app.include_router(chat.router, prefix="/api")
app.include_router(docs_pages.router)


@app.get("/")
def root():
    return RedirectResponse(url="/admin")


@app.get("/health")
def health():
    return {"status": "ok"}


app.mount("/admin", StaticFiles(directory="static", html=True), name="admin")
