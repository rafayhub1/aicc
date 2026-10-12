"""Retrieve one handbook rule for a student question.

Each Q&A is one chunk. Ranking mixes word overlap with a multilingual
vector, so a paraphrase in English or Urdu script can still land on the
same rule. The reply text is the handbook line, not model prose.
"""

import math
import re
from collections import Counter
from functools import lru_cache
from pathlib import Path

from app.embeddings import semantic_scores

PROJECT_ROOT = Path(__file__).resolve().parent.parent
HANDBOOK_PATH = PROJECT_ROOT / "docs" / "lgu_aicc_qa_knowledge_base (1).md"

_WORD = re.compile(r"[a-z0-9%]+|[\u0600-\u06ff]+", re.IGNORECASE)
_URDU = re.compile(r"[\u0600-\u06ff]")
_LINE = re.compile(r"^(?:-\s*)?\*\*(Q|A|UQ|UA|RQ|RA):\*\*\s*(.+?)\s*$")
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
    "kab",
    "kb",
    "milegi",
    "milega",
    "milengi",
    "milenge",
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
    "credits": ("credit",),
    "cancelled": ("cancel",),
    "canceled": ("cancel",),
    "cancels": ("cancel",),
    "cancellation": ("cancel",),
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
    "khulti": ("timings",),
    "khulta": ("timings",),
    "khulte": ("timings",),
    "khula": ("timings",),
    "کھلتی": ("timings",),
    "کھلتا": ("timings",),
    "اوقات": ("timings",),
    "timing": ("timings",),
    "hours": ("timings",),
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
    "khulti",
    "khulta",
    "khulte",
    "milegi",
    "milega",
}

# Words that name no campus topic. "kya rules hain" is only these.
_BROAD = {
    "rules",
    "rule",
    "policy",
    "policies",
    "qawaid",
    "university",
    "lgu",
    "student",
    "students",
    "campus",
    "help",
    "info",
    "information",
    "question",
    "sawal",
}

_MENU = {
    "en": "That question is very broad. Ask about attendance, exams, fees, scholarships, the hostel, or the library.",
    "ur": "یہ سوال بہت عام ہے۔ حاضری، امتحان، فیس، اسکالرشپ، ہاسٹل یا لائبریری کے بارے میں پوچھیں۔",
    "roman": "Yeh sawal bohot aam hai. Hazri, imtehan, fee, scholarship, hostel, ya library ke bare mein poochain.",
}

_CLARIFY = {
    "en": "Which of these do you mean?",
    "ur": "ان میں سے کون سا سوال ہے؟",
    "roman": "In mein se kaun sa sawal hai?",
}

_MISSING = {
    "en": "This is not in the student handbook. Confirm it with the Registrar or the relevant office.",
    "ur": "یہ بات اسٹوڈنٹ ہینڈ بک میں موجود نہیں۔ رجسٹرار یا متعلقہ دفتر سے تصدیق کر لیں۔",
    "roman": "Yeh baat student handbook mein maujood nahi. Registrar ya mutaliqa office se confirm kar lo.",
}


def _tokens(text: str) -> list[str]:
    cleaned = text.translate(_DIGIT_MAP).lower()
    for mark in ("?", "؟", "،", ",", "!", "؛", ".", "۔"):
        cleaned = cleaned.replace(mark, " ")
    return [word for word in _WORD.findall(cleaned) if word not in _STOP and len(word) > 1]


def _bag(text: str) -> Counter:
    counts: Counter = Counter()
    for token in _tokens(text):
        counts[token] += 1
        for alias in _ALIASES.get(token, ()):
            counts[alias] += 1
    return counts


def detect_language(message: str) -> str:
    if _URDU.search(message):
        return "ur"
    raw = _WORD.findall(message.translate(_DIGIT_MAP).lower())
    if sum(1 for word in raw if word in _ROMAN_MARKERS) >= 2:
        return "roman"
    return "en"


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
            question_counts: Counter = Counter()
            for question in questions:
                question_counts.update(_bag(question))
            answer_counts = _bag(
                " ".join([block["a"], block.get("ua", ""), block.get("ra", "")])
            )
            # The question is the chunk title. Repeating it keeps a shared
            # word in the answer from outranking the rule the student asked.
            term_counts = Counter()
            for token, count in question_counts.items():
                term_counts[token] += count * 3
            term_counts.update(answer_counts)
            entries.append(
                {
                    "id": f"{_PREFIXES[slot]}-{counts[slot]:02d}",
                    "q": block["q"],
                    "answer": block["a"],
                    "ua": block.get("ua", ""),
                    "ra": block.get("ra", ""),
                    "questions": [question for question in questions if question],
                    "uq": block.get("uq", ""),
                    "rq": block.get("rq", ""),
                    "q_terms": frozenset(question_counts),
                    "tf": dict(term_counts),
                    "length": sum(term_counts.values()) or 1,
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


def _content_query(message: str) -> Counter:
    query = _bag(message)
    for term in [term for term in query if term in _BROAD]:
        del query[term]
    return query


def _bm25(query: Counter, entry: dict, document_frequency: Counter, average_length: float, total: int) -> float:
    asked = set(query)
    score = 0.0
    k1 = 1.2
    b = 0.2
    length = entry["length"]
    for term, query_count in query.items():
        frequency = entry["tf"].get(term, 0)
        if not frequency:
            continue
        docs_with_term = document_frequency.get(term, 0)
        idf = math.log(1 + (total - docs_with_term + 0.5) / (docs_with_term + 0.5))
        denominator = frequency + k1 * (1 - b + b * length / average_length)
        score += idf * (frequency * (k1 + 1) / denominator) * (1 + math.log(query_count))
    overlap = asked & entry["q_terms"]
    score += 1.5 * len(overlap) / max(1.0, len(entry["q_terms"]) ** 0.5)
    for question in entry["questions"]:
        terms = set(_content_query(question))
        if not terms:
            continue
        if terms <= asked:
            # Every meaningful word of this question is in what the student asked.
            score += 12
            break
        covered = terms & asked
        if len(covered) >= 2 and len(covered) / len(terms) >= 0.8:
            score += 8
            break
    return score


def _scored(message: str) -> list[tuple[float, float, dict]]:
    entries = list(load_entries())
    if not entries:
        return []
    query = _content_query(message)
    document_frequency: Counter = Counter()
    for entry in entries:
        document_frequency.update(entry["tf"].keys())
    average_length = sum(entry["length"] for entry in entries) / len(entries)
    vectors = semantic_scores(message, entries, HANDBOOK_PATH.stat().st_mtime_ns)
    rows = []
    for entry in entries:
        lexical = _bm25(query, entry, document_frequency, average_length, len(entries))
        cosine = vectors.get(entry["id"], 0.0)
        if lexical <= 0 and cosine <= 0:
            continue
        rows.append((lexical, cosine, entry))
    return rows


def _with_score(lexical: float, cosine: float, entry: dict) -> dict:
    return {**entry, "score": round(max(lexical, cosine), 3)}


def retrieve(message: str) -> dict:
    """One rule, a short list of rules to choose from, or no handbook match."""
    if not _content_query(message):
        return {"kind": "clarify", "entries": []}
    rows = _scored(message)
    if not rows:
        return {"kind": "missing", "entries": []}
    by_words = sorted(rows, key=lambda row: row[0], reverse=True)
    by_meaning = sorted(rows, key=lambda row: row[1], reverse=True)
    word_gap = by_words[0][0] - (by_words[1][0] if len(by_words) > 1 else 0.0)
    if by_words[0][0] >= 8 and word_gap >= 4:
        return {"kind": "answer", "entries": [_with_score(*by_words[0])]}
    meaning_gap = by_meaning[0][1] - (by_meaning[1][1] if len(by_meaning) > 1 else 0.0)
    if by_meaning[0][1] >= 0.70 and meaning_gap >= 0.05:
        return {"kind": "answer", "entries": [_with_score(*by_meaning[0])]}
    pool = [row for row in by_words if row[0] >= 4.5]
    if not pool:
        return {"kind": "missing", "entries": []}
    pool.sort(key=lambda row: (row[1], row[0]), reverse=True)
    return {"kind": "clarify", "entries": [_with_score(*row) for row in pool[:3]]}


def search_handbook(message: str, history: list[dict] | None = None, limit: int = 2) -> list[dict]:
    del history
    found = retrieve(message)
    if found["kind"] == "missing" or not found["entries"]:
        return []
    return found["entries"][:limit]


def plan_reply(message: str) -> dict:
    """Decide whether the question names one rule, or is too broad to answer."""
    return retrieve(message)


def clarification_text(message: str, entries: list[dict]) -> str:
    language = detect_language(message)
    if not entries:
        return _MENU[language]
    heading = _CLARIFY[language]
    lines = [heading]
    for entry in entries[:3]:
        if language == "ur" and entry.get("uq"):
            lines.append(f"- {entry['uq']}")
        elif language == "roman" and entry.get("rq"):
            lines.append(f"- {entry['rq']}")
        else:
            lines.append(f"- {entry['q']}")
    return "\n".join(lines)


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
    if len(entries) > 1 and entries[1]["score"] >= entries[0]["score"] * 0.92:
        picked.append(entries[1])
    texts = []
    for entry in picked:
        text = localized_answer(entry, language)
        if text and text not in texts:
            texts.append(text)
    return "\n\n".join(texts)

