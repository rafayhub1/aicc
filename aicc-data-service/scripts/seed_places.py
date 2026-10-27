"""Load places.csv into the mobile Firestore project.

    python scripts/seed_places.py
    python scripts/seed_places.py --dry-run
"""

import csv
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

DATA = ROOT / "data"


def load_places(path: Path) -> list[dict]:
    places = []
    with path.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            lat = float(row["lat"])
            lng = float(row["lng"])
            if not -90 <= lat <= 90 or not -180 <= lng <= 180:
                raise SystemExit(f"{row['id']} has coordinates outside the valid range.")
            aliases = [part.strip() for part in row.get("aliases", "").split(";") if part.strip()]
            places.append(
                {
                    "id": row["id"].strip(),
                    "name": row["name"].strip(),
                    "aliases": aliases,
                    "category": row["category"].strip(),
                    "lat": lat,
                    "lng": lng,
                    "entrance": {"lat": lat, "lng": lng},
                    "building": row.get("building", "").strip(),
                    "floor": row.get("floor", "").strip(),
                    "hours": row.get("hours", "").strip(),
                    "description": row.get("description", "").strip(),
                    "photoUrl": "",
                    "nodeId": row.get("node_id", "").strip(),
                    "isActive": True,
                }
            )
    if len(places) < 20:
        raise SystemExit(f"Expected at least 20 places, found {len(places)}.")
    return places


def main() -> None:
    dry_run = "--dry-run" in sys.argv
    places = load_places(DATA / "places.csv")
    print(f"Validated {len(places)} places.")
    if dry_run:
        return
    from app.firebase import get_mobile_db

    db = get_mobile_db()
    stamp = datetime.now(timezone.utc).isoformat()
    batch = db.batch()
    for place in places:
        payload = dict(place)
        payload["updatedAt"] = stamp
        batch.set(db.collection("places").document(place["id"]), payload)
    batch.commit()
    print("Seeded Firestore places.")


if __name__ == "__main__":
    main()
