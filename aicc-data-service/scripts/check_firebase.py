"""Write, read, and delete a single Firestore document to verify credentials."""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from dotenv import load_dotenv

load_dotenv(ROOT / ".env")

from app.firebase import get_db


def main() -> None:
    db = get_db()
    ref = db.collection("_healthcheck").document("ping")
    ref.set({"ok": True, "source": "check_firebase.py"})
    data = ref.get().to_dict()
    print("Read back:", data)
    ref.delete()
    print("Deleted healthcheck doc. Firebase connection OK.")


if __name__ == "__main__":
    main()
