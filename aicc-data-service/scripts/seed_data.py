"""
Idempotent seed: 72 students (3 per cohort × 24 cohorts) with courses,
notifications, and documents. Safe to re-run (deterministic document IDs).
"""

from __future__ import annotations

import argparse
import hashlib
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from dotenv import load_dotenv

load_dotenv(ROOT / ".env")

from google.cloud import firestore

from app.academics import (
    COURSE_CATALOG,
    INTAKE_BY_SEMESTER,
    all_cohorts,
    courses_for_department_semester,
)
from app.firebase import get_db

BATCH_LIMIT = 500

FIRST_NAMES = [
    "Abdul",
    "Ayesha",
    "Hamza",
    "Fatima",
    "Usman",
    "Sana",
    "Bilal",
    "Hira",
    "Omar",
    "Zainab",
    "Ali",
    "Maryam",
    "Hassan",
    "Noor",
    "Ahmed",
    "Sara",
    "Imran",
    "Laiba",
    "Kamran",
    "Amna",
    "Rafay",
    "Maha",
    "Danish",
    "Iqra",
]

LAST_NAMES = [
    "Khan",
    "Malik",
    "Sheikh",
    "Butt",
    "Raza",
    "Hussain",
    "Iqbal",
    "Siddiqui",
    "Chaudhry",
    "Mirza",
    "Akram",
    "Tariq",
    "Yousaf",
    "Anwar",
    "Saleem",
    "Farooq",
]


def stable_float(seed: str, lo: float, hi: float) -> float:
    digest = hashlib.sha256(seed.encode()).hexdigest()
    value = int(digest[:8], 16) / 0xFFFFFFFF
    return round(lo + value * (hi - lo), 2)


def stable_int(seed: str, lo: int, hi: int) -> int:
    digest = hashlib.sha256(seed.encode()).hexdigest()
    value = int(digest[:8], 16)
    return lo + (value % (hi - lo + 1))


def student_name(index: int) -> str:
    first = FIRST_NAMES[index % len(FIRST_NAMES)]
    last = LAST_NAMES[(index // len(FIRST_NAMES)) % len(LAST_NAMES)]
    return f"{first} {last}"


def build_student_plans() -> list[dict]:
    plans: list[dict] = []
    reg_counter: dict[tuple[str, int], int] = defaultdict(int)
    global_index = 0

    for cohort in all_cohorts():
        department = cohort["department"]
        semester = cohort["semester"]
        section = cohort["section"]
        intake = INTAKE_BY_SEMESTER[semester]

        for slot in range(1, 4):
            reg_counter[(department, semester)] += 1
            num = reg_counter[(department, semester)]
            registration = f"{intake}-{department}-{num:03d}"
            global_index += 1

            plans.append(
                {
                    "id": registration,
                    "name": student_name(global_index),
                    "registrationNumber": registration,
                    "department": department,
                    "semester": semester,
                    "section": section,
                    "cgpaOverall": stable_float(registration, 2.35, 3.95),
                }
            )

    return plans


def course_operations(db, student: dict) -> list:
    ops = []
    student_ref = db.collection("students").document(student["id"])
    current_sem = student["semester"]

    for sem in range(1, current_sem + 1):
        for template in courses_for_department_semester(student["department"], sem):
            course_id = f"{sem}_{template['courseCode']}"
            attendance = stable_float(
                f"{student['id']}-{course_id}", 65.0, 98.0
            )
            ref = student_ref.collection("courses").document(course_id)
            ops.append(
                (
                    ref,
                    {
                        "courseName": template["courseName"],
                        "courseCode": template["courseCode"],
                        "attendancePercent": attendance,
                        "semester": sem,
                    },
                )
            )
    return ops


def notification_operations(db, student: dict) -> list:
    student_ref = db.collection("students").document(student["id"])
    base_time = datetime(2026, 9, 1, 9, 0, tzinfo=timezone.utc)

    templates = [
        ("notif_1", "fee_challan_ready", "Your fee challan for the current semester is ready."),
        ("notif_2", "roll_slip_ready", "Your roll number slip has been issued."),
        ("notif_3", "sign_in", "Please sign in for today's scheduled class."),
    ]

    ops = []
    for doc_id, ntype, message in templates:
        ref = student_ref.collection("notifications").document(doc_id)
        ts = base_time.replace(day=min(28, 1 + stable_int(student["id"] + doc_id, 0, 20)))
        ops.append(
            (
                ref,
                {
                    "type": ntype,
                    "message": message,
                    "timestamp": ts,
                    "read": doc_id == "notif_3",
                },
            )
        )
    return ops


def document_operations(db, student: dict) -> list:
    student_ref = db.collection("students").document(student["id"])
    ready = stable_int(student["id"], 0, 1) == 1

    return [
        (
            student_ref.collection("documents").document("fee_challan"),
            {
                "docType": "fee_challan",
                "status": "ready" if ready else "pending",
                "fileUrl": None,
            },
        ),
        (
            student_ref.collection("documents").document("roll_number_slip"),
            {
                "docType": "roll_number_slip",
                "status": "ready",
                "fileUrl": None,
            },
        ),
    ]


def commit_batches(db, operations: list[tuple]) -> int:
    committed = 0
    batch = db.batch()
    count_in_batch = 0

    for ref, data in operations:
        batch.set(ref, data, merge=True)
        count_in_batch += 1
        committed += 1

        if count_in_batch >= BATCH_LIMIT:
            batch.commit()
            batch = db.batch()
            count_in_batch = 0

    if count_in_batch:
        batch.commit()

    return committed


def wipe_students(db) -> None:
    """Remove all students and subcollections (use before full re-seed if needed)."""
    from app.firestore_helpers import delete_subcollections

    for doc in db.collection("students").stream():
        delete_subcollections(db, doc.id)
        doc.reference.delete()
    print("Wiped existing students collection.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed AICC dummy Firestore data")
    parser.add_argument(
        "--wipe",
        action="store_true",
        help="Delete all existing students before seeding",
    )
    args = parser.parse_args()

    db = get_db()

    if args.wipe:
        wipe_students(db)

    students = build_student_plans()
    operations: list[tuple] = []

    for student in students:
        student_ref = db.collection("students").document(student["id"])
        payload = {k: v for k, v in student.items() if k != "id"}
        operations.append((student_ref, payload))
        operations.extend(course_operations(db, student))
        operations.extend(notification_operations(db, student))
        operations.extend(document_operations(db, student))

    total = commit_batches(db, operations)

    print(f"Seeded {len(students)} students.")
    print(f"Committed {total} Firestore writes (batched, max {BATCH_LIMIT} per batch).")
    print(f"Course catalog entries: {len(COURSE_CATALOG)} department-semester pairs.")


if __name__ == "__main__":
    main()
