from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles

from app.routers import catalog, courses, docs_pages, documents, notifications, stats, students

app = FastAPI(title="AICC Dummy Data Service", version="0.4.0")

app.include_router(catalog.router, prefix="/api")
app.include_router(students.router, prefix="/api")
app.include_router(stats.router, prefix="/api")
app.include_router(courses.router, prefix="/api")
app.include_router(notifications.router, prefix="/api")
app.include_router(documents.router, prefix="/api")
app.include_router(docs_pages.router)


@app.get("/")
def root():
    return RedirectResponse(url="/admin")


@app.get("/health")
def health():
    return {"status": "ok"}


app.mount("/admin", StaticFiles(directory="static", html=True), name="admin")
