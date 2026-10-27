"""Campus assistant routes.

POST /api/chat answers a question from the handbook. POST /api/chat/transcribe
turns a short audio clip into text. Place ids are chosen from the handbook,
not by the language model.
"""

from typing import Literal

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel, Field

from app.groq_client import GroqError, answer_question, transcribe_audio
from app.handbook import plan_reply
from app.knowledge import linked_place_ids

router = APIRouter(prefix="/chat", tags=["chat"])


class ChatTurn(BaseModel):
    """One earlier message in the conversation."""
    role: Literal["user", "assistant"]
    content: str = Field(max_length=800)


class ChatAsk(BaseModel):
    """The student's question plus a short history."""
    message: str = Field(min_length=1, max_length=1000)
    history: list[ChatTurn] = Field(default_factory=list, max_length=6)


class ChatAnswer(BaseModel):
    """Assistant text and any campus places the app should show as cards."""
    text: str
    place_ids: list[str] = Field(default_factory=list)


def groq_failure_status(error: GroqError) -> int:
    """Map an upstream Groq failure to 503 when the app should retry, otherwise 502."""
    if error.status in {401, 429, 503}:
        return 503
    return 502


@router.post("/transcribe", response_model=ChatAnswer)
async def transcribe_speech_to_text(file: UploadFile = File(...)):
    """Turn an uploaded recording into text."""
    audio = await file.read()
    if len(audio) < 800:
        raise HTTPException(status_code=400, detail="The recording was too short. Speak, then tap stop.")
    if len(audio) > 8 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="The recording is too long.")
    try:
        text = transcribe_audio(file.filename or "speech.m4a", audio, file.content_type or "audio/mp4")
    except GroqError as error:
        raise HTTPException(status_code=groq_failure_status(error), detail=error.message) from error
    return ChatAnswer(text=text)


@router.post("", response_model=ChatAnswer)
def answer_campus_question(body: ChatAsk):
    """Answer a campus question and attach any matching place ids."""
    try:
        text = answer_question(body.message, [turn.model_dump() for turn in body.history])
    except GroqError as error:
        raise HTTPException(status_code=groq_failure_status(error), detail=error.message) from error
    place_ids: list[str] = []
    try:
        plan = plan_reply(body.message)
        place_ids = linked_place_ids(body.message, plan.get("entries") or [])
    except Exception:
        place_ids = linked_place_ids(body.message, [])
    return ChatAnswer(text=text, place_ids=place_ids)
