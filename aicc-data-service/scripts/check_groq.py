"""Check the Groq chat key. Never prints the key."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.groq_client import GroqError, answer_question


def main() -> None:
    try:
        text = answer_question("What is the minimum attendance for a final exam?", [])
    except GroqError as error:
        print("status", error.status)
        print("message", error.message)
        return
    print("status", 200)
    print("answer", text[:300])


if __name__ == "__main__":
    main()
