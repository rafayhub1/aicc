import firebase_admin
from firebase_admin import auth, credentials, firestore

from app.config import settings

_db = None
_mobile_db = None
_MOBILE_APP = "mobile"


def init_firebase() -> None:
    if firebase_admin._apps.get("[DEFAULT]") is not None:
        return
    cred = credentials.Certificate(settings.get_service_account_dict())
    firebase_admin.initialize_app(cred)


def get_db():
    global _db
    if _db is None:
        init_firebase()
        _db = firestore.client()
    return _db


def get_mobile_app():
    existing = firebase_admin._apps.get(_MOBILE_APP)
    if existing is not None:
        return existing
    cred = credentials.Certificate(settings.get_mobile_service_account_dict())
    return firebase_admin.initialize_app(cred, name=_MOBILE_APP)


def get_mobile_auth():
    get_mobile_app()
    return auth


def get_mobile_db():
    global _mobile_db
    if _mobile_db is None:
        _mobile_db = firestore.client(app=get_mobile_app())
    return _mobile_db
