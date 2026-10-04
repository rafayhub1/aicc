from fastapi import APIRouter, HTTPException

from google.cloud import firestore

from app.firebase import get_db
from app.firestore_helpers import get_student_data
from app.models import NotificationIn, NotificationOut, NotificationUpdate
from app.serializers import doc_to_dict

router = APIRouter(
    prefix="/students/{student_id}/notifications", tags=["notifications"]
)


def _require_student(db, student_id: str) -> None:
    if get_student_data(db, student_id) is None:
        raise HTTPException(status_code=404, detail="Student not found")


def _to_notification_out(doc) -> NotificationOut:
    data = doc_to_dict(doc)
    return NotificationOut(id=doc.id, **data)


@router.get("", response_model=list[NotificationOut])
def list_notifications(student_id: str):
    db = get_db()
    _require_student(db, student_id)

    coll = (
        db.collection("students")
        .document(student_id)
        .collection("notifications")
    )
    return [_to_notification_out(doc) for doc in coll.stream()]


@router.post("", response_model=NotificationOut, status_code=201)
def create_notification(student_id: str, notification: NotificationIn):
    db = get_db()
    _require_student(db, student_id)

    payload = notification.model_dump()
    payload["timestamp"] = firestore.SERVER_TIMESTAMP

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("notifications")
        .document()
    )
    ref.set(payload)

    saved = ref.get()
    data = doc_to_dict(saved)
    return NotificationOut(id=ref.id, **data)


@router.patch("/{notification_id}", response_model=NotificationOut)
def update_notification(
    student_id: str, notification_id: str, update: NotificationUpdate
):
    db = get_db()
    _require_student(db, student_id)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("notifications")
        .document(notification_id)
    )
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Notification not found")

    ref.update(update.model_dump())
    return _to_notification_out(ref.get())


@router.delete("/{notification_id}", status_code=204)
def delete_notification(student_id: str, notification_id: str):
    db = get_db()
    _require_student(db, student_id)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("notifications")
        .document(notification_id)
    )
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Notification not found")
    ref.delete()
