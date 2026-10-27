"""Turn Firestore values into JSON-safe Python types."""

from datetime import datetime

from google.cloud.firestore_v1._helpers import DatetimeWithNanoseconds


def serialize_value(value):
    """Convert a Firestore timestamp to an ISO string. Other values pass through."""
    if isinstance(value, (DatetimeWithNanoseconds, datetime)):
        return value.isoformat()
    return value


def doc_to_dict(doc) -> dict:
    """Read one Firestore document into a plain dictionary."""
    data = doc.to_dict() or {}
    return {key: serialize_value(val) for key, val in data.items()}
