import json
import re
from functools import lru_cache
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
HANDBOOK_PATH = PROJECT_ROOT / "docs" / "lgu_aicc_knowledge_base (1).json"

_WORD = re.compile(r"[a-z0-9%]+")
_STOP = {
    "a",
    "an",
    "the",
    "is",
    "are",
    "was",
    "were",
    "do",
    "does",
    "did",
    "can",
    "could",
    "i",
    "my",
    "me",
    "we",
    "you",
    "your",
    "to",
    "of",
    "in",
    "on",
    "for",
    "and",
    "or",
    "if",
    "at",
    "what",
    "how",
    "when",
    "where",
    "why",
    "who",
    "which",
    "please",
    "tell",
    "about",
    "with",
    "from",
    "that",
    "this",
    "it",
    "be",
    "have",
    "has",
    "will",
    "should",
    "need",
    "much",
    "many",
}


def _tokens(text: str) -> list[str]:
    return [word for word in _WORD.findall(text.lower()) if word not in _STOP and len(word) > 1]


@lru_cache(maxsize=1)
def load_entries() -> tuple[dict, ...]:
    payload = json.loads(HANDBOOK_PATH.read_text(encoding="utf-8"))
    entries = []
    for entry in payload.get("entries", []):
        keywords = [str(keyword).lower() for keyword in entry.get("keywords", [])]
        questions = [str(question) for question in entry.get("student_questions", [])]
        details = [str(line) for line in entry.get("details", [])[:3]]
        entries.append(
            {
                "id": str(entry.get("id", "")),
                "title": str(entry.get("title", "")),
                "answer": str(entry.get("answer", "")),
                "details": details,
                "keywords": keywords,
                "questions": questions,
                "related": [str(item) for item in entry.get("related", [])],
            }
        )
    return tuple(entries)


def _score(entry: dict, query_text: str, query_tokens: set[str]) -> int:
    score = 0
    for keyword in entry["keywords"]:
        if keyword and re.search(rf"\b{re.escape(keyword)}\b", query_text):
            score += 10 + len(keyword.split())
            continue
        parts = set(_tokens(keyword))
        overlap = len(parts & query_tokens)
        if parts and overlap == len(parts):
            score += 6
        elif overlap:
            score += overlap
    for question in entry["questions"]:
        parts = _tokens(question)
        overlap = len(set(parts) & query_tokens)
        if overlap >= 2:
            score += overlap * 3
    title_overlap = len(set(_tokens(entry["title"])) & query_tokens)
    score += title_overlap * 2
    return score


def search_handbook(message: str, history: list[dict] | None = None, limit: int = 3) -> list[dict]:
    entries = load_entries()
    query_text = message.lower()
    query_tokens = set(_tokens(message))
    if len(query_tokens) < 2 and history:
        for turn in reversed(history):
            if turn.get("role") == "user" and turn.get("content"):
                query_text = f"{turn['content']} {message}".lower()
                query_tokens |= set(_tokens(str(turn["content"])))
                break
    ranked = []
    for entry in entries:
        score = _score(entry, query_text, query_tokens)
        if score > 0:
            ranked.append((score, entry))
    ranked.sort(key=lambda item: item[0], reverse=True)
    if not ranked or ranked[0][0] < 6:
        return []
    best = ranked[0][0]
    chosen = [entry for score, entry in ranked if score >= max(6, int(best * 0.45))]
    return chosen[:limit]


def format_chunks(entries: list[dict]) -> str:
    if not entries:
        return "No handbook entry matched this question."
    blocks = []
    for entry in entries:
        lines = [f"[{entry['id']}] {entry['title']}", f"Answer: {entry['answer']}"]
        if entry["details"]:
            lines.append("Details:")
            lines.extend(f"- {detail}" for detail in entry["details"])
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks)
