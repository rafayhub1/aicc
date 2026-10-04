import firebase_admin
from firebase_admin import credentials, firestore

from app.config import settings

_db = None


def init_firebase() -> None:
    if firebase_admin._apps:
        return
    cred = credentials.Certificate(settings.get_service_account_dict())
    firebase_admin.initialize_app(cred)


def get_db():
    global _db
    if _db is None:
        init_firebase()
        _db = firestore.client()
    return _db
