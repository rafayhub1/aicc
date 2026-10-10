from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from firebase_admin import auth
from google.cloud import firestore
from pydantic import BaseModel, Field

from app.academics import DEPARTMENT_CODES, SECTIONS
from app.config import settings
from app.firebase import get_db, get_mobile_app, get_mobile_db
from app.firestore_helpers import delete_subcollections, student_exists
from app.models import DepartmentCode, NotificationType, Section
from app.serializers import doc_to_dict

router = APIRouter(prefix="/admin", tags=["admin"])

ACCOUNT_DOMAIN = "aicc-demo.local"


class PasswordIn(BaseModel):
    password: str = Field(min_length=6, max_length=128)


class BroadcastIn(BaseModel):
    message: str = Field(min_length=1, max_length=500)
    type: NotificationType = "other"
    department: DepartmentCode | None = None
    semester: int | None = Field(default=None, ge=1, le=4)
    section: Section | None = None


def _mobile_unavailable(exc: Exception) -> HTTPException:
    return HTTPException(
        status_code=503,
        detail=(
            "The mobile Firebase project is not configured on the server. "
            f"{exc}"
        ),
    )


def _account_email(identifier: str) -> str:
    local = identifier.strip().lower()
    if not local or "@" in local or " " in local:
        raise HTTPException(status_code=400, detail="Invalid account name")
    return f"{local}@{ACCOUNT_DOMAIN}"


def _iso_ms(millis: int | None) -> str | None:
    if not millis:
        return None
    return datetime.fromtimestamp(millis / 1000, tz=timezone.utc).isoformat()


def _require_admin_password() -> str:
    password = (settings.admin_password or "").strip()
    if len(password) < 6:
        raise HTTPException(
            status_code=503,
            detail="Set ADMIN_PASSWORD (at least 6 characters) on the server.",
        )
    return password


def require_admin(authorization: str | None = Header(default=None)) -> dict:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Admin sign-in required")
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Admin sign-in required")
    try:
        app = get_mobile_app()
        decoded = auth.verify_id_token(token, app=app)
    except ValueError as exc:
        raise _mobile_unavailable(exc) from exc
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Admin sign-in required") from exc
    if decoded.get("admin") is not True:
        raise HTTPException(status_code=403, detail="Admin access required")
    return decoded


def _lookup_user(email: str):
    try:
        return auth.get_user_by_email(email, app=get_mobile_app())
    except ValueError as exc:
        raise _mobile_unavailable(exc) from exc
    except auth.UserNotFoundError:
        return None


def _account_payload(identifier: str) -> dict:
    user = _lookup_user(_account_email(identifier))
    if user is None:
        return {"exists": False, "uid": None, "created": None, "lastSignIn": None}
    meta = user.user_metadata
    return {
        "exists": True,
        "uid": user.uid,
        "created": _iso_ms(meta.creation_timestamp if meta else None),
        "lastSignIn": _iso_ms(meta.last_sign_in_timestamp if meta else None),
    }


def _delete_matching(db, collection: str, uid: str) -> None:
    query = db.collection(collection).where("user_id", "==", uid)
    while True:
        docs = list(query.limit(300).stream())
        if not docs:
            return
        batch = db.batch()
        for doc in docs:
            batch.delete(doc.reference)
        batch.commit()


def _delete_mobile_account(identifier: str) -> bool:
    email = _account_email(identifier)
    user = _lookup_user(email)
    if user is None:
        return False
    app = get_mobile_app()
    db = get_mobile_db()
    for name in ("chat_messages", "chat_sessions", "activity_events"):
        _delete_matching(db, name, user.uid)
    db.collection("users").document(user.uid).delete()
    auth.delete_user(user.uid, app=app)
    return True


@router.post("/bootstrap")
def bootstrap_admin():
    username = settings.admin_username.strip().lower()
    if not username:
        raise HTTPException(status_code=503, detail="Set ADMIN_USERNAME on the server.")
    password = _require_admin_password()
    email = _account_email(username)
    try:
        app = get_mobile_app()
        db = get_mobile_db()
    except ValueError as exc:
        raise _mobile_unavailable(exc) from exc

    try:
        user = auth.get_user_by_email(email, app=app)
        user = auth.update_user(user.uid, password=password, app=app)
        created = False
    except auth.UserNotFoundError:
        user = auth.create_user(email=email, password=password, app=app)
        created = True

    auth.set_custom_user_claims(user.uid, {"admin": True}, app=app)
    db.collection("users").document(user.uid).set(
        {
            "role": "admin",
            "username": username,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    return {"ok": True, "created": created, "uid": user.uid}


@router.get("/accounts/{identifier}")
def get_account(identifier: str, _admin: dict = Depends(require_admin)):
    return _account_payload(identifier)


@router.post("/accounts/{identifier}/password")
def set_password(
    identifier: str,
    body: PasswordIn,
    _admin: dict = Depends(require_admin),
):
    user = _lookup_user(_account_email(identifier))
    if user is None:
        raise HTTPException(status_code=404, detail="This student has no app account yet")
    auth.update_user(user.uid, password=body.password, app=get_mobile_app())
    return {"ok": True}


@router.delete("/accounts/{identifier}", status_code=204)
def delete_account(identifier: str, _admin: dict = Depends(require_admin)):
    if not _delete_mobile_account(identifier):
        raise HTTPException(status_code=404, detail="This student has no app account yet")


@router.delete("/students/{student_id}", status_code=204)
def delete_student_fully(student_id: str, _admin: dict = Depends(require_admin)):
    db = get_db()
    if not student_exists(db, student_id):
        raise HTTPException(status_code=404, detail="Student not found")
    _delete_mobile_account(student_id)
    delete_subcollections(db, student_id)
    db.collection("students").document(student_id).delete()


@router.post("/notifications/broadcast")
def broadcast_notification(
    body: BroadcastIn,
    _admin: dict = Depends(require_admin),
):
    if body.department and body.department not in DEPARTMENT_CODES:
        raise HTTPException(status_code=400, detail="Invalid department")
    if body.section and body.section not in SECTIONS:
        raise HTTPException(status_code=400, detail="Invalid section")

    db = get_db()
    query = db.collection("students")
    if body.department:
        query = query.where("department", "==", body.department)
    if body.semester is not None:
        query = query.where("semester", "==", body.semester)
    if body.section:
        query = query.where("section", "==", body.section)

    count = 0
    for student in query.stream():
        student.reference.collection("notifications").add(
            {
                "type": body.type,
                "message": body.message,
                "read": False,
                "timestamp": firestore.SERVER_TIMESTAMP,
            }
        )
        count += 1
    return {"count": count}


@router.get("/activity")
def list_activity(
    limit: int = Query(default=100, ge=1, le=200),
    _admin: dict = Depends(require_admin),
):
    try:
        db = get_mobile_db()
    except ValueError as exc:
        raise _mobile_unavailable(exc) from exc

    docs = list(
        db.collection("activity_events")
        .order_by("timestamp", direction=firestore.Query.DESCENDING)
        .limit(limit)
        .stream()
    )
    profiles: dict[str, dict] = {}
    for doc in docs:
        uid = (doc.to_dict() or {}).get("user_id")
        if uid and uid not in profiles:
            profile = db.collection("users").document(uid).get()
            profiles[uid] = doc_to_dict(profile) if profile.exists else {}

    items = []
    for doc in docs:
        data = doc_to_dict(doc)
        uid = data.get("user_id") or ""
        profile = profiles.get(uid, {})
        registration = profile.get("registrationNumber") or profile.get("username") or ""
        items.append(
            {
                "id": doc.id,
                "type": data.get("type") or "other",
                "timestamp": data.get("timestamp"),
                "read": data.get("read") is True,
                "registrationNumber": registration,
            }
        )
    return items
