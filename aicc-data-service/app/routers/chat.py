from typing import Literal

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel, Field

from app.groq_client import GroqError, answer_question, transcribe_audio

router = APIRouter(prefix="/chat", tags=["chat"])


class ChatTurn(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(max_length=800)


class ChatAsk(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    history: list[ChatTurn] = Field(default_factory=list, max_length=6)


class ChatAnswer(BaseModel):
    text: str


def _http_status(error: GroqError) -> int:
    if error.status in {401, 429, 503}:
        return 503
    return 502


@router.post("/transcribe", response_model=ChatAnswer)
async def transcribe(file: UploadFile = File(...)):
    audio = await file.read()
    if len(audio) < 800:
        raise HTTPException(status_code=400, detail="The recording was too short. Speak, then tap stop.")
    if len(audio) > 8 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="The recording is too long.")
    try:
        text = transcribe_audio(file.filename or "speech.m4a", audio, file.content_type or "audio/mp4")
    except GroqError as error:
        raise HTTPException(status_code=_http_status(error), detail=error.message) from error
    return ChatAnswer(text=text)


@router.post("", response_model=ChatAnswer)
def ask(body: ChatAsk):
    try:
        text = answer_question(body.message, [turn.model_dump() for turn in body.history])
    except GroqError as error:
        raise HTTPException(status_code=_http_status(error), detail=error.message) from error
    return ChatAnswer(text=text)
