"""Campus-wide counts and CGPA bands for the admin dashboard. GET /api/stats."""

import time

from fastapi import APIRouter

from app.academics import DEPARTMENTS, SECTIONS, SEMESTERS
from app.firebase import get_db

router = APIRouter(tags=["stats"])

_CACHE_TTL_SECONDS = 300
_cache: dict = {"expires": 0.0, "payload": None}


def _round(value: float) -> float:
    return round(value, 2)


def _mean(values: list[float]) -> float | None:
    if not values:
        return None
    return _round(sum(values) / len(values))


def _cgpa_band(cgpa: float) -> int:
    if cgpa >= 4.0:
        return 7
    return min(int(cgpa / 0.5), 7)


def _compute() -> dict:
    db = get_db()
    students = []
    for doc in db.collection("students").stream():
        data = doc.to_dict() or {}
        data["id"] = doc.id
        students.append(data)

    dept_of = {student["id"]: student.get("department") for student in students}
    attendance_by_student: dict[str, list[float]] = {}
    attendance_by_dept: dict[str, list[float]] = {}

    for doc in db.collection_group("courses").stream():
        data = doc.to_dict() or {}
        parent = doc.reference.parent.parent
        if parent is None:
            continue
        student_id = parent.id
        percent = float(data.get("attendancePercent") or 0)
        attendance_by_student.setdefault(student_id, []).append(percent)
        department = dept_of.get(student_id)
        if department:
            attendance_by_dept.setdefault(department, []).append(percent)

    pending_documents = 0
    for doc in db.collection_group("documents").stream():
        data = doc.to_dict() or {}
        if data.get("status") == "pending":
            pending_documents += 1

    cgpa_values = [
        float(student["cgpaOverall"])
        for student in students
        if student.get("cgpaOverall") is not None
    ]
    bands = [{"label": f"{index * 0.5:.1f}–{(index + 1) * 0.5:.1f}", "count": 0} for index in range(8)]
    for cgpa in cgpa_values:
        bands[_cgpa_band(cgpa)]["count"] += 1

    by_department = []
    for department in DEPARTMENTS:
        code = department["code"]
        cohort = [student for student in students if student.get("department") == code]
        cohort_cgpa = [
            float(student["cgpaOverall"])
            for student in cohort
            if student.get("cgpaOverall") is not None
        ]
        by_department.append(
            {
                "code": code,
                "name": department["name"],
                "count": len(cohort),
                "averageCgpa": _mean(cohort_cgpa),
                "averageAttendance": _mean(attendance_by_dept.get(code, [])),
            }
        )

    by_semester_section = []
    for semester in SEMESTERS:
        for section in SECTIONS:
            count = sum(
                1
                for student in students
                if student.get("semester") == semester and student.get("section") == section
            )
            by_semester_section.append(
                {"semester": semester, "section": section, "count": count}
            )

    at_risk = []
    for student in students:
        percents = attendance_by_student.get(student["id"], [])
        average = _mean(percents)
        if average is None or average >= 75:
            continue
        at_risk.append(
            {
                "id": student["id"],
                "name": student.get("name") or student["id"],
                "registrationNumber": student.get("registrationNumber") or student["id"],
                "department": student.get("department"),
                "semester": student.get("semester"),
                "section": student.get("section"),
                "attendancePercent": average,
            }
        )
    at_risk.sort(key=lambda row: row["attendancePercent"])

    all_attendance = [value for values in attendance_by_student.values() for value in values]
    return {
        "totalStudents": len(students),
        "averageCgpa": _mean(cgpa_values),
        "averageAttendance": _mean(all_attendance),
        "pendingDocuments": pending_documents,
        "byDepartment": by_department,
        "bySemesterSection": by_semester_section,
        "cgpaBands": bands,
        "atRisk": at_risk[:12],
    }


@router.get("/stats")
def get_stats(refresh: bool = False):
    now = time.monotonic()
    cached = _cache["payload"]
    if not refresh and cached is not None and now < _cache["expires"]:
        return {**cached, "cached": True}

    payload = _compute()
    _cache["payload"] = payload
    _cache["expires"] = now + _CACHE_TTL_SECONDS
    return {**payload, "cached": False}
