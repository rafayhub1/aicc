"""Campus place catalog stored in the mobile Firebase places collection.

Students can list and open places. Creating, editing, and deleting a place
requires the admin password header.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from app.firebase import get_mobile_db
from app.models import PlaceIn, PlaceUpdate
from app.routers.admin import require_admin

router = APIRouter(tags=["places"])


def places_database():
    """Mobile Firestore client, or HTTP 503 when campus places are unavailable."""
    try:
        return get_mobile_db()
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Campus places are not available. {exc}") from exc


def place_response(doc_id: str, data: dict) -> dict:
    """Attach the document id to the stored place fields."""
    body = dict(data)
    body["id"] = doc_id
    return body


@router.get("/places")
def list_places():
    """Return every campus place, sorted by name."""
    docs = places_database().collection("places").stream()
    places = [place_response(doc.id, doc.to_dict() or {}) for doc in docs]
    places.sort(key=lambda item: item.get("name", ""))
    return places


@router.get("/places/{place_id}")
def get_place(place_id: str):
    """Return one campus place, or 404 when the id is unknown."""
    snapshot = places_database().collection("places").document(place_id).get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Place not found.")
    return place_response(snapshot.id, snapshot.to_dict() or {})


@router.post("/admin/places", status_code=201)
def create_place(body: PlaceIn, _admin: dict = Depends(require_admin)):
    """Create a place. Admin only. The id must be new."""
    db = places_database()
    ref = db.collection("places").document(body.id)
    if ref.get().exists:
        raise HTTPException(status_code=409, detail="That place id already exists.")
    payload = body.model_dump()
    payload["updatedAt"] = datetime.now(timezone.utc).isoformat()
    if payload.get("entrance") is None:
        payload["entrance"] = {"lat": body.lat, "lng": body.lng}
    ref.set(payload)
    return place_response(body.id, payload)


@router.put("/admin/places/{place_id}")
def update_place(place_id: str, body: PlaceUpdate, _admin: dict = Depends(require_admin)):
    """Merge the supplied fields into an existing place. Admin only."""
    ref = places_database().collection("places").document(place_id)
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Place not found.")
    changes = body.model_dump(exclude_none=True)
    if not changes:
        raise HTTPException(status_code=400, detail="Nothing to update.")
    changes["updatedAt"] = datetime.now(timezone.utc).isoformat()
    ref.set(changes, merge=True)
    return place_response(place_id, ref.get().to_dict() or {})


@router.delete("/admin/places/{place_id}")
def delete_place(place_id: str, _admin: dict = Depends(require_admin)):
    """Delete a place. Admin only."""
    ref = places_database().collection("places").document(place_id)
    if not ref.get().exists:
        raise HTTPException(status_code=404, detail="Place not found.")
    ref.delete()
    return {"deleted": place_id}

