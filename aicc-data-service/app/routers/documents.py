from fastapi import APIRouter, HTTPException, Request

from app.firebase import get_db
from app.firestore_helpers import get_student_data
from app.models import DocumentIn, DocumentOut, DocumentUpdate
from app.serializers import doc_to_dict

router = APIRouter(prefix="/students/{student_id}/documents", tags=["documents"])

PAGE_SLUGS = {
    "fee_challan": "fee-challan",
    "roll_number_slip": "roll-slip",
}


def _require_student(db, student_id: str) -> None:
    if get_student_data(db, student_id) is None:
        raise HTTPException(status_code=404, detail="Student not found")


def public_document_url(request: Request, student_id: str, doc_type: str) -> str | None:
    slug = PAGE_SLUGS.get(doc_type)
    if not slug:
        return None
    base = str(request.base_url).rstrip("/")
    return f"{base}/students/{student_id}/{slug}"


def _apply_file_url(data: dict, request: Request, student_id: str) -> dict:
    if data.get("fileUrl"):
        return data
    url = public_document_url(request, student_id, data.get("docType", ""))
    if not url:
        return data
    return {**data, "fileUrl": url}


def _to_document_out(doc, request: Request, student_id: str) -> DocumentOut:
    data = _apply_file_url(doc_to_dict(doc), request, student_id)
    return DocumentOut(id=doc.id, **data)


@router.get("", response_model=list[DocumentOut])
def list_documents(student_id: str, request: Request):
    db = get_db()
    _require_student(db, student_id)

    coll = (
        db.collection("students")
        .document(student_id)
        .collection("documents")
    )
    return [_to_document_out(doc, request, student_id) for doc in coll.stream()]


@router.post("", response_model=DocumentOut, status_code=201)
def create_document(student_id: str, document: DocumentIn, request: Request):
    db = get_db()
    _require_student(db, student_id)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("documents")
        .document()
    )
    payload = document.model_dump()
    ref.set(payload)
    return DocumentOut(id=ref.id, **_apply_file_url(payload, request, student_id))


@router.put("/{document_id}", response_model=DocumentOut)
def update_document(
    student_id: str, document_id: str, document: DocumentIn, request: Request
):
    db = get_db()
    _require_student(db, student_id)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("documents")
        .document(document_id)
    )
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Document not found")

    payload = document.model_dump()
    ref.update(payload)
    return DocumentOut(id=document_id, **_apply_file_url(payload, request, student_id))


@router.patch("/{document_id}", response_model=DocumentOut)
def partial_update_document(
    student_id: str, document_id: str, update: DocumentUpdate, request: Request
):
    db = get_db()
    _require_student(db, student_id)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("documents")
        .document(document_id)
    )
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Document not found")

    changes = update.model_dump(exclude_unset=True)
    if not changes:
        return _to_document_out(doc, request, student_id)

    ref.update(changes)
    return _to_document_out(ref.get(), request, student_id)


@router.delete("/{document_id}", status_code=204)
def delete_document(student_id: str, document_id: str):
    db = get_db()
    _require_student(db, student_id)

    ref = (
        db.collection("students")
        .document(student_id)
        .collection("documents")
        .document(document_id)
    )
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Document not found")
    ref.delete()
