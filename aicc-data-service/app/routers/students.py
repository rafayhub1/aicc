from fastapi import APIRouter, HTTPException, Query

from app.academics import DEPARTMENT_CODES, SECTIONS
from app.firebase import get_db
from app.firestore_helpers import delete_subcollections, student_exists
from app.models import StudentIn, StudentOut, StudentUpdate
from app.serializers import doc_to_dict

router = APIRouter(prefix="/students", tags=["students"])


def _student_id(registration_number: str) -> str:
    return registration_number.strip()


def _to_student_out(doc) -> StudentOut:
    data = doc_to_dict(doc)
    return StudentOut(id=doc.id, **data)


@router.get("", response_model=list[StudentOut])
def list_students(
    department: str | None = Query(default=None),
    semester: int | None = Query(default=None, ge=1, le=4),
    section: str | None = Query(default=None),
):
    if department and department not in DEPARTMENT_CODES:
        raise HTTPException(status_code=400, detail="Invalid department")
    if section and section not in SECTIONS:
        raise HTTPException(status_code=400, detail="Invalid section")

    db = get_db()
    query = db.collection("students")
    if department:
        query = query.where("department", "==", department)
    if semester is not None:
        query = query.where("semester", "==", semester)
    if section:
        query = query.where("section", "==", section)

    return [_to_student_out(doc) for doc in query.stream()]


@router.post("", response_model=StudentOut, status_code=201)
def create_student(student: StudentIn):
    db = get_db()
    doc_id = _student_id(student.registrationNumber)
    ref = db.collection("students").document(doc_id)
    if ref.get().exists:
        raise HTTPException(status_code=409, detail="Student already exists")
    ref.set(student.model_dump())
    return StudentOut(id=doc_id, **student.model_dump())


@router.get("/{student_id}", response_model=StudentOut)
def get_student(student_id: str):
    db = get_db()
    doc = db.collection("students").document(student_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Student not found")
    return _to_student_out(doc)


@router.put("/{student_id}", response_model=StudentOut)
def update_student(student_id: str, student: StudentIn):
    db = get_db()
    ref = db.collection("students").document(student_id)
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Student not found")

    new_id = _student_id(student.registrationNumber)
    payload = student.model_dump()
    if new_id != student_id:
        if db.collection("students").document(new_id).get().exists:
            raise HTTPException(
                status_code=409, detail="Target registration number already exists"
            )
        old_ref = ref
        db.collection("students").document(new_id).set(payload)
        old_ref.delete()
        return StudentOut(id=new_id, **payload)

    ref.update(payload)
    return StudentOut(id=student_id, **payload)


@router.patch("/{student_id}", response_model=StudentOut)
def partial_update_student(student_id: str, update: StudentUpdate):
    db = get_db()
    ref = db.collection("students").document(student_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Student not found")

    current = doc_to_dict(doc)
    changes = update.model_dump(exclude_unset=True)
    merged = {**current, **changes}
    student = StudentIn(**merged)
    return update_student(student_id, student)


@router.delete("/{student_id}", status_code=204)
def delete_student(student_id: str):
    db = get_db()
    if not student_exists(db, student_id):
        raise HTTPException(status_code=404, detail="Student not found")
    delete_subcollections(db, student_id)
    db.collection("students").document(student_id).delete()
