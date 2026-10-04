from google.cloud.firestore_v1 import Client

from app.serializers import doc_to_dict

SUBCOLLECTIONS = ("courses", "notifications", "documents")


def student_exists(db: Client, student_id: str) -> bool:
    return db.collection("students").document(student_id).get().exists


def get_student_data(db: Client, student_id: str) -> dict | None:
    doc = db.collection("students").document(student_id).get()
    if not doc.exists:
        return None
    return doc_to_dict(doc)


def delete_subcollections(db: Client, student_id: str) -> None:
    student_ref = db.collection("students").document(student_id)
    for name in SUBCOLLECTIONS:
        _delete_collection(db, student_ref.collection(name))


def _delete_collection(db: Client, coll_ref, batch_size: int = 500) -> None:
    while True:
        docs = list(coll_ref.limit(batch_size).stream())
        if not docs:
            break
        batch = db.batch()
        for doc in docs:
            batch.delete(doc.reference)
        batch.commit()
