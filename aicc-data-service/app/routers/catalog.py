"""Fixed academic choices the app uses in filters: departments, semesters, sections."""

from fastapi import APIRouter

from app.academics import DEPARTMENTS, SECTIONS, SEMESTERS

router = APIRouter(tags=["catalog"])


@router.get("/catalog")
def get_catalog():
    """Return the department, semester, and section lists."""
    return {
        "departments": DEPARTMENTS,
        "semesters": SEMESTERS,
        "sections": SECTIONS,
    }
