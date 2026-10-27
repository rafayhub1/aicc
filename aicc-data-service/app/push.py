"""Store a student's FCM device tokens and send a best-effort push when a notice is saved."""

import logging

from firebase_admin import messaging
from google.cloud import firestore

from app.firebase import get_mobile_app

log = logging.getLogger(__name__)

TOKENS_FIELD = "fcm_tokens"

TITLES = {
    "fee_challan_ready": "Fee challan ready",
    "roll_slip_ready": "Roll number slip ready",
    "sign_in": "Sign-in reminder",
}


def add_token(student_ref, token: str) -> None:
    student_ref.update({TOKENS_FIELD: firestore.ArrayUnion([token])})


def remove_token(student_ref, token: str) -> None:
    student_ref.update({TOKENS_FIELD: firestore.ArrayRemove([token])})


def notify_student(student_snapshot, notification_type: str, message: str) -> None:
    """Best-effort push; failures never block saving the in-app notification."""
    data = student_snapshot.to_dict() or {}
    tokens = [t for t in data.get(TOKENS_FIELD) or [] if isinstance(t, str) and t]
    if not tokens:
        return
    push = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(
            title=TITLES.get(notification_type, "Notice"),
            body=message,
        ),
        data={"type": notification_type},
        android=messaging.AndroidConfig(priority="high"),
    )
    try:
        result = messaging.send_each_for_multicast(push, app=get_mobile_app())
    except Exception:
        log.exception("Push send failed for student %s", student_snapshot.id)
        return

    stale = [
        tokens[index]
        for index, response in enumerate(result.responses)
        if not response.success
        and isinstance(
            response.exception,
            (messaging.UnregisteredError, messaging.SenderIdMismatchError),
        )
    ]
    if stale:
        student_snapshot.reference.update({TOKENS_FIELD: firestore.ArrayRemove(stale)})
