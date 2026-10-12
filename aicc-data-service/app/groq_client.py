import json
import re
import uuid
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from app.config import settings
from app.handbook import format_chunks, search_handbook

SYSTEM_INSTRUCTION = """You are AICC, the LGU campus assistant.
Answer only from the handbook entries below. Quote numbers, days, and fees exactly as written.
If the entries say the answer is not covered, or no entry matched, say it is not in the student handbook and name the office to confirm with.
Do not invent the student's own attendance, CGPA, fee status, document status, or a teacher's location. Tell them to ask for that directly.
Reply in the student's language, including Urdu or Roman Urdu. Use 2 to 4 short sentences. No headings."""

_THINK_BLOCK = re.compile(r"<think>.*?</think>", re.DOTALL | re.IGNORECASE)


class GroqError(Exception):
    def __init__(self, status: int, message: str):
        self.status = status
        self.message = message
        super().__init__(message)


def build_messages(message: str, history: list[dict], handbook_context: str) -> list[dict]:
    messages = [
        {
            "role": "system",
            "content": f"{SYSTEM_INSTRUCTION}\n\nHandbook entries:\n{handbook_context}",
        }
    ]
    for turn in history[-4:]:
        role = "user" if turn.get("role") == "user" else "assistant"
        content = " ".join(str(turn.get("content", "")).split())[:400]
        if content:
            messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": message.strip()})
    return messages


def extract_chat_text(payload: dict) -> str:
    choices = payload.get("choices") or []
    if not choices or not isinstance(choices[0], dict):
        return ""
    message = choices[0].get("message") or {}
    content = message.get("content") if isinstance(message, dict) else ""
    if not isinstance(content, str):
        return ""
    return _THINK_BLOCK.sub("", content).strip()


def _public_error(status: int, payload: dict, api_key: str) -> str:
    error = payload.get("error", payload)
    if isinstance(error, dict):
        message = str(error.get("message") or error.get("type") or "Groq request failed")
    else:
        message = str(error)
    if api_key:
        message = message.replace(api_key, "[key]")
    if status == 401:
        return "The Groq API key was rejected."
    if status == 429:
        return "The free Groq quota for this model is used up for now. Try again later."
    return message[:300]


def _post_json(url: str, payload: dict, api_key: str, timeout: int = 30) -> dict:
    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "User-Agent": "AICC/1.0",
        },
    )
    return _read(request, api_key, timeout)


def _read(request: Request, api_key: str, timeout: int) -> dict:
    try:
        with urlopen(request, timeout=timeout) as response:
            data = json.load(response)
    except HTTPError as error:
        raw = error.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = {"error": {"message": raw[:300]}}
        raise GroqError(error.code, _public_error(error.code, parsed, api_key)) from error
    except URLError as error:
        raise GroqError(503, "Could not reach Groq.") from error
    if not isinstance(data, dict):
        raise GroqError(502, "Groq returned an unexpected response.")
    return data


def _api_key() -> str:
    api_key = (settings.groq_api_key or "").strip()
    if not api_key:
        raise GroqError(503, "GROQ_API_KEY is not configured.")
    return api_key


def answer_question(message: str, history: list[dict]) -> str:
    api_key = _api_key()
    model = (settings.groq_chat_model or "qwen/qwen3.8-27b").strip()
    chunks = search_handbook(message, history)
    context = format_chunks(chunks)
    payload = {
        "model": model,
        "messages": build_messages(message, history, context),
        "temperature": 0.1,
        "max_tokens": 120 if not chunks else 180,
    }
    try:
        data = _post_json(
            "https://api.groq.com/openai/v1/chat/completions",
            {**payload, "reasoning_effort": "none"},
            api_key,
        )
    except GroqError as error:
        if error.status != 400:
            raise
        data = _post_json(
            "https://api.groq.com/openai/v1/chat/completions",
            payload,
            api_key,
        )
    text = extract_chat_text(data)
    if not text:
        raise GroqError(502, "Groq returned an empty answer.")
    return text


def transcribe_audio(filename: str, audio: bytes, content_type: str) -> str:
    api_key = _api_key()
    model = (settings.groq_speech_model or "whisper-large-v3").strip()
    safe_name = filename.replace('"', "") or "speech.m4a"
    boundary = uuid.uuid4().hex
    body = b"".join(
        [
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\n{model}\r\n".encode(),
            (
                "--"
                + boundary
                + "\r\nContent-Disposition: form-data; name=\"prompt\"\r\n\r\n"
                + "Student question about campus rules, attendance, fees, or teachers. English, Urdu, or Roman Urdu.\r\n"
            ).encode(),
            (
                f"--{boundary}\r\n"
                f"Content-Disposition: form-data; name=\"file\"; filename=\"{safe_name}\"\r\n"
                f"Content-Type: {content_type or 'audio/mp4'}\r\n\r\n"
            ).encode(),
            audio,
            f"\r\n--{boundary}--\r\n".encode(),
        ]
    )
    request = Request(
        "https://api.groq.com/openai/v1/audio/transcriptions",
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "User-Agent": "AICC/1.0",
        },
    )
    data = _read(request, api_key, 45)
    text = data.get("text")
    if not isinstance(text, str) or not text.strip():
        raise GroqError(502, "Whisper could not hear any words.")
    return text.strip()
