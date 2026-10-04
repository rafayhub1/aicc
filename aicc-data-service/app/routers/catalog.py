from fastapi import APIRouter

from app.academics import DEPARTMENTS, SECTIONS, SEMESTERS

router = APIRouter(tags=["catalog"])


@router.get("/catalog")
def get_catalog():
    return {
        "departments": DEPARTMENTS,
        "semesters": SEMESTERS,
        "sections": SECTIONS,
    }
