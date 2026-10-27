"""Courses stored under one academic student. Paths start with /api/students/{id}/courses."""

from fastapi import APIRouter, HTTPException, Query

from app.firebase import get_db
from app.firestore_helpers import get_student_data
from app.models import CourseIn, CourseOut
from app.serializers import doc_to_dict

router = APIRouter(prefix="/students/{student_id}/courses", tags=["courses"])


def _require_student(db, student_id: str) -> dict:
    student = get_student_data(db, student_id)
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    return student


def _to_course_out(doc) -> CourseOut:
    data = doc_to_dict(doc)
    return CourseOut(id=doc.id, **data)


def _validate_course_semester(student: dict, course: CourseIn) -> None:
    if course.semester > student["semester"]:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Course semester {course.semester} exceeds "
                f"student's current semester {student['semester']}"
            ),
        )


@router.get("", response_model=list[CourseOut])
def list_courses(
    student_id: str,
    semester: int | None = Query(default=None, ge=1, le=4),
):
    db = get_db()
    _require_student(db, student_id)

    query = db.collection("students").document(student_id).collection("courses")
    if semester is not None:
        query = query.where("semester", "==", semester)

    return [_to_course_out(doc) for doc in query.stream()]


@router.post("", response_model=CourseOut, status_code=201)
def create_course(student_id: str, course: CourseIn):
    db = get_db()
    student = _require_student(db, student_id)
    _validate_course_semester(student, course)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("courses")
        .document()
    )
    ref.set(course.model_dump())
    return CourseOut(id=ref.id, **course.model_dump())


@router.put("/{course_id}", response_model=CourseOut)
def update_course(student_id: str, course_id: str, course: CourseIn):
    db = get_db()
    student = _require_student(db, student_id)
    _validate_course_semester(student, course)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("courses")
        .document(course_id)
    )
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Course not found")

    ref.update(course.model_dump())
    return CourseOut(id=course_id, **course.model_dump())


@router.delete("/{course_id}", status_code=204)
def delete_course(student_id: str, course_id: str):
    db = get_db()
    _require_student(db, student_id)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("courses")
        .document(course_id)
    )
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Course not found")
    ref.delete()
