"""Find the handbook answer for a student question.

The source is the Q&A file in docs. English, Urdu, and Roman Urdu all
land on the same rule.
"""

import re
from functools import lru_cache
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
HANDBOOK_PATH = PROJECT_ROOT / "docs" / "lgu_aicc_qa_knowledge_base (1).md"

_WORD = re.compile(r"[a-z0-9%]+|[\u0600-\u06ff]+", re.IGNORECASE)
_URDU = re.compile(r"[\u0600-\u06ff]")
_LINE = re.compile(r"^(?:-\s*)?\*\*(Q|A|UQ|UA|RQ|RA):\*\*\s*(.+?)\s*$")
_NUMBER = re.compile(r"\d+(?:\.\d+)?")
_DIGIT_MAP = str.maketrans("۰۱۲۳۴۵۶۷۸۹٪", "0123456789%")
_FIELDS = {"Q": "q", "A": "a", "UQ": "uq", "UA": "ua", "RQ": "rq", "RA": "ra"}
_PREFIXES = ("ACP", "EXM", "FEE", "DSC", "FAC", "SRV", "ADM")

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
    "kya",
    "kyu",
    "kyun",
    "kyon",
    "hai",
    "hain",
    "ho",
    "hon",
    "hoon",
    "hun",
    "hota",
    "hoti",
    "hote",
    "mera",
    "meri",
    "mere",
    "mujhe",
    "kitni",
    "kitna",
    "kitne",
    "kaise",
    "kese",
    "chahiye",
    "chaiye",
    "batao",
    "btao",
    "bata",
    "nahi",
    "nahin",
    "sakta",
    "sakti",
    "sakte",
    "karun",
    "karo",
    "karna",
    "kar",
    "liye",
    "yeh",
    "ye",
    "woh",
    "wo",
    "apna",
    "apni",
    "agar",
    "lekin",
    "bhi",
    "ka",
    "ki",
    "ke",
    "ko",
    "se",
    "par",
    "pe",
    "mein",
    "aur",
    "ya",
    "کیا",
    "کیوں",
    "ہے",
    "ہیں",
    "ہوں",
    "ہو",
    "ہوتا",
    "ہوتی",
    "ہوتے",
    "میرا",
    "میری",
    "میرے",
    "مجھے",
    "کتنی",
    "کتنا",
    "کتنے",
    "کیسے",
    "چاہیے",
    "بتائیں",
    "بتاؤ",
    "نہیں",
    "سکتا",
    "سکتی",
    "سکتے",
    "کروں",
    "کریں",
    "کرنا",
    "لیے",
    "یہ",
    "وہ",
    "اپنا",
    "اپنی",
    "اگر",
    "لیکن",
    "بھی",
    "کا",
    "کی",
    "کے",
    "کو",
    "سے",
    "پر",
    "میں",
    "اور",
    "یا",
    "نے",
    "تو",
    "تک",
    "بعد",
    "پہلے",
    "ایک",
    "کوئی",
    "کچھ",
}

# Student wording that should hit the English rule.
_ALIASES = {
    "حاضری": ("attendance",),
    "اٹینڈنس": ("attendance",),
    "غیرحاضری": ("attendance", "absence"),
    "چھٹی": ("leave",),
    "امتحان": ("exam",),
    "امتحانات": ("exam",),
    "پیپر": ("exam", "paper"),
    "فیس": ("fee",),
    "چالان": ("challan", "fee"),
    "اسکالرشپ": ("scholarship",),
    "وظائف": ("scholarship",),
    "ہاسٹل": ("hostel",),
    "لائبریری": ("library",),
    "کتاب": ("book", "library"),
    "ڈگری": ("degree",),
    "سمسٹر": ("semester",),
    "فریز": ("freeze",),
    "وڈرا": ("withdraw",),
    "ریفنڈ": ("refund",),
    "واپسی": ("refund",),
    "جرمانہ": ("fine",),
    "سزا": ("fine", "penalty"),
    "لباس": ("dress",),
    "ڈریس": ("dress",),
    "سگریٹ": ("smoking",),
    "تمباکو": ("smoking", "tobacco"),
    "منشیات": ("drugs",),
    "رگنگ": ("ragging",),
    "ہراسانی": ("harassment",),
    "شکایت": ("complaint", "grievance"),
    "انٹرنشپ": ("internship",),
    "نوکری": ("job", "placement"),
    "سوسائٹی": ("society",),
    "کریڈٹ": ("credit",),
    "رجسٹریشن": ("registration",),
    "مائیگریشن": ("migration",),
    "منتقلی": ("migration",),
    "ٹرانسکرپٹ": ("transcript",),
    "رزلٹ": ("result",),
    "نتیجہ": ("result",),
    "سلپ": ("slip",),
    "پروبیشن": ("probation",),
    "معذوری": ("disability",),
    "تھیسس": ("thesis",),
    "موبائل": ("phone", "mobile"),
    "فون": ("phone",),
    "نقل": ("cheating",),
    "لڑکوں": ("male",),
    "لڑکیوں": ("female",),
    "boys": ("male",),
    "girls": ("female",),
    "larkon": ("male",),
    "larkiyon": ("female",),
    "hazri": ("attendance",),
    "hajri": ("attendance",),
    "chutti": ("leave",),
    "imtehan": ("exam",),
    "imtihan": ("exam",),
    "paper": ("exam",),
    "fees": ("fee",),
    "challan": ("challan", "fee"),
    "jurmana": ("fine",),
    "saza": ("fine", "penalty"),
    "libas": ("dress",),
    "tambaku": ("smoking", "tobacco"),
    "manshiyat": ("drugs",),
    "harasani": ("harassment",),
    "shikayat": ("complaint", "grievance"),
    "naukri": ("job", "placement"),
    "wapas": ("refund",),
    "freeze": ("freeze",),
    "withdraw": ("withdraw",),
}

_ROMAN_MARKERS = {
    "kya",
    "kyu",
    "kyun",
    "kyon",
    "hai",
    "hain",
    "hoon",
    "hun",
    "hota",
    "hoti",
    "hote",
    "chahiye",
    "chaiye",
    "kitni",
    "kitna",
    "kitne",
    "kaise",
    "kese",
    "batao",
    "btao",
    "mujhe",
    "mera",
    "meri",
    "mere",
    "nahi",
    "nahin",
    "sakta",
    "sakti",
    "sakte",
    "karun",
    "hazri",
    "hajri",
    "imtehan",
    "imtihan",
    "chutti",
    "jurmana",
    "saza",
    "wapas",
    "harasani",
    "libas",
    "manshiyat",
    "tambaku",
    "naukri",
    "shikayat",
}

_MISSING = {
    "en": "This is not in the student handbook. Confirm it with the Registrar or the relevant office.",
    "ur": "یہ بات اسٹوڈنٹ ہینڈ بک میں موجود نہیں۔ رجسٹرار یا متعلقہ دفتر سے تصدیق کر لیں۔",
    "roman": "Yeh baat student handbook mein maujood nahi. Registrar ya mutaliqa office se confirm kar lo.",
}


def _tokens(text: str) -> list[str]:
    cleaned = text.translate(_DIGIT_MAP).lower()
    return [word for word in _WORD.findall(cleaned) if word not in _STOP and len(word) > 1]


def _expand(tokens: set[str]) -> set[str]:
    expanded = set(tokens)
    for token in tokens:
        expanded.update(_ALIASES.get(token, ()))
    return expanded


def detect_language(message: str) -> str:
    if _URDU.search(message):
        return "ur"
    raw = _WORD.findall(message.translate(_DIGIT_MAP).lower())
    if sum(1 for word in raw if word in _ROMAN_MARKERS) >= 2:
        return "roman"
    return "en"


def _numbers(text: str) -> set[str]:
    return set(_NUMBER.findall(text.translate(_DIGIT_MAP)))


def is_echo(question: str, answer: str) -> bool:
    asked = set(_tokens(question))
    replied = set(_tokens(answer))
    if not replied:
        return True
    return len(asked & replied) / len(replied) >= 0.8


def drops_handbook_number(reply: str, fact: str) -> bool:
    required = _numbers(fact)
    if not required:
        return False
    return required.isdisjoint(_numbers(reply))


def load_entries() -> tuple[dict, ...]:
    stamp = HANDBOOK_PATH.stat().st_mtime_ns
    return _load_entries(str(HANDBOOK_PATH), stamp)


@lru_cache(maxsize=2)
def _load_entries(path: str, stamp: int) -> tuple[dict, ...]:
    del stamp
    section_index = -1
    counts = [0, 0, 0, 0, 0, 0, 0]
    block: dict[str, str] = {}
    entries: list[dict] = []

    def flush() -> None:
        nonlocal block
        if block.get("q") and block.get("a"):
            slot = section_index if 0 <= section_index < len(_PREFIXES) else 0
            counts[slot] += 1
            questions = [block["q"], block.get("uq", ""), block.get("rq", "")]
            combined = " ".join(
                [
                    block["q"],
                    block["a"],
                    block.get("uq", ""),
                    block.get("ua", ""),
                    block.get("rq", ""),
                    block.get("ra", ""),
                ]
            )
            entries.append(
                {
                    "id": f"{_PREFIXES[slot]}-{counts[slot]:02d}",
                    "q": block["q"],
                    "answer": block["a"],
                    "ua": block.get("ua", ""),
                    "ra": block.get("ra", ""),
                    "questions": [question for question in questions if question],
                    "tokens": _expand(set(_tokens(combined))),
                }
            )
        block = {}

    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            flush()
            section_index += 1
            continue
        match = _LINE.match(line.strip())
        if not match:
            continue
        key, value = match.group(1), match.group(2).strip()
        if key == "Q":
            flush()
        block[_FIELDS[key]] = value
    flush()
    return tuple(entries)


def _score(entry: dict, expanded: set[str]) -> int:
    overlap = entry["tokens"] & expanded
    if not overlap:
        return 0
    score = len(overlap) * 5
    if any(len(token) >= 6 for token in overlap):
        score += 4
    for question in entry["questions"]:
        qtoks = set(_tokens(question))
        if not qtoks:
            continue
        inter = qtoks & expanded
        if inter == qtoks:
            score += 8 + len(qtoks)
        elif len(inter) >= 2:
            score += len(inter)
    return score


def search_handbook(message: str, history: list[dict] | None = None, limit: int = 3) -> list[dict]:
    query = message
    query_tokens = set(_tokens(message))
    if len(query_tokens) < 2 and not _URDU.search(message) and history:
        for turn in reversed(history):
            if turn.get("role") == "user" and turn.get("content"):
                query = f"{turn['content']} {message}"
                query_tokens |= set(_tokens(str(turn["content"])))
                break
    expanded = _expand(query_tokens)
    if not expanded:
        return []
    ranked = []
    for entry in load_entries():
        score = _score(entry, expanded)
        if score > 0:
            ranked.append((score, entry))
    ranked.sort(key=lambda item: item[0], reverse=True)
    if not ranked or ranked[0][0] < 8:
        return []
    best = ranked[0][0]
    chosen = []
    for score, entry in ranked:
        if score < max(8, int(best * 0.45)):
            break
        chosen.append({**entry, "score": score})
        if len(chosen) >= limit:
            break
    return chosen


def localized_answer(entry: dict, language: str) -> str:
    if language == "ur" and entry.get("ua"):
        return entry["ua"]
    if language == "roman" and entry.get("ra"):
        return entry["ra"]
    return entry["answer"]


def missing_handbook_answer(language: str) -> str:
    return _MISSING.get(language, _MISSING["en"])


def speak_entries(entries: list[dict], language: str) -> str:
    if not entries:
        return missing_handbook_answer(language)
    picked = [entries[0]]
    if len(entries) > 1 and entries[1]["score"] >= max(8, int(entries[0]["score"] * 0.8)):
        picked.append(entries[1])
    texts = []
    for entry in picked:
        text = localized_answer(entry, language)
        if text and text not in texts:
            texts.append(text)
    return "\n\n".join(texts)


def format_chunks(entries: list[dict]) -> str:
    if not entries:
        return "No handbook entry matched this question."
    return "\n\n".join(f"[{entry['id']}] {entry['q']}\nAnswer: {entry['answer']}" for entry in entries)
