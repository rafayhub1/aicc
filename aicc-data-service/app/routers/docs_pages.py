"""Printable HTML pages for a student's fee challan and exam roll slip."""

import hashlib
from datetime import date

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from app.academics import DEPARTMENTS, INTAKE_BY_SEMESTER, courses_for_department_semester
from app.config import PROJECT_ROOT
from app.fees import amount_in_words, fee_lines, fee_total
from app.firebase import get_db
from app.firestore_helpers import get_student_data
from app.serializers import doc_to_dict

router = APIRouter(tags=["documents-pages"])
templates = Jinja2Templates(directory=str(PROJECT_ROOT / "templates"))
templates.env.filters["rupees"] = lambda value: f"{int(value):,}"

DOCUMENT_IDS = {
    "fee_challan": "fee_challan",
    "roll_slip": "roll_number_slip",
}

DOCUMENT_TITLES = {
    "fee_challan": "Fee challan",
    "roll_slip": "Roll number slip",
}


def session_label(semester: int) -> str:
    intake = INTAKE_BY_SEMESTER.get(semester, "FA26")
    season = "Fall" if intake.startswith("FA") else "Spring"
    return f"{season} 20{intake[2:]}"


def term_dates(semester: int) -> tuple[str, str]:
    intake = INTAKE_BY_SEMESTER.get(semester, "FA26")
    year = 2000 + int(intake[2:])
    if intake.startswith("FA"):
        issued = date(year, 9, 1)
        due = date(year, 9, 15)
    else:
        issued = date(year, 2, 1)
        due = date(year, 2, 15)
    return issued.strftime("%d %B %Y"), due.strftime("%d %B %Y")


def challan_number(registration: str) -> str:
    digest = hashlib.sha256(registration.encode()).hexdigest()
    number = int(digest[:8], 16) % 1_000_000
    return f"AICC-2026-{number:06d}"


def department_name(code: str) -> str:
    for department in DEPARTMENTS:
        if department["code"] == code:
            return department["name"]
    return code


def document_status(db, student_id: str, document_id: str) -> str | None:
    doc = (
        db.collection("students")
        .document(student_id)
        .collection("documents")
        .document(document_id)
        .get()
    )
    if not doc.exists:
        return None
    return (doc.to_dict() or {}).get("status")


def current_courses(db, student: dict) -> list[dict]:
    semester = student["semester"]
    stored = []
    coll = db.collection("students").document(student["id"]).collection("courses")
    for doc in coll.stream():
        data = doc_to_dict(doc)
        if data.get("semester") == semester:
            stored.append(data)
    if stored:
        stored.sort(key=lambda course: course.get("courseCode") or "")
        return stored
    return courses_for_department_semester(student["department"], semester)


def unavailable(request: Request, state: str, heading: str, message: str, status_code: int):
    return templates.TemplateResponse(
        request,
        "document_unavailable.html",
        {"state": state, "heading": heading, "message": message},
        status_code=status_code,
    )


def load_student(request: Request, student_id: str):
    student = get_student_data(get_db(), student_id)
    if student is None:
        return None, unavailable(
            request,
            "not_found",
            "Record not found",
            "No student is registered under this number.",
            404,
        )
    student["id"] = student_id
    return student, None


@router.get("/students/{student_id}/fee-challan", response_class=HTMLResponse)
def fee_challan_page(student_id: str, request: Request):
    student, error = load_student(request, student_id)
    if error is not None:
        return error

    status = document_status(get_db(), student_id, DOCUMENT_IDS["fee_challan"])
    if status != "ready":
        return unavailable(
            request,
            "pending",
            "Not issued yet",
            "Your fee challan has not been issued yet. Check again after the accounts office releases it.",
            200,
        )

    lines = fee_lines(student["department"])
    total = fee_total(student["department"])
    issue_date, due_date = term_dates(student["semester"])
    return templates.TemplateResponse(
        request,
        "fee_challan_doc.html",
        {
            "student": student,
            "department_name": department_name(student["department"]),
            "session": session_label(student["semester"]),
            "lines": lines,
            "total": total,
            "amount_words": amount_in_words(total),
            "challan_number": challan_number(student["registrationNumber"]),
            "issue_date": issue_date,
            "due_date": due_date,
            "copies": ["Bank copy", "University copy", "Student copy"],
        },
    )


@router.get("/students/{student_id}/roll-slip", response_class=HTMLResponse)
def roll_slip_page(student_id: str, request: Request):
    student, error = load_student(request, student_id)
    if error is not None:
        return error

    status = document_status(get_db(), student_id, DOCUMENT_IDS["roll_slip"])
    if status != "ready":
        return unavailable(
            request,
            "pending",
            "Not issued yet",
            "Your roll number slip has not been issued yet. Check again after the examinations office releases it.",
            200,
        )

    registration = student["registrationNumber"]
    return templates.TemplateResponse(
        request,
        "roll_slip_doc.html",
        {
            "student": student,
            "department_name": department_name(student["department"]),
            "session": session_label(student["semester"]),
            "roll_number": registration,
            "courses": current_courses(get_db(), student),
        },
    )
