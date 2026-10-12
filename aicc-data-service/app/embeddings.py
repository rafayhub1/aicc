"""Vectors for the 100 handbook rules.

One vector per rule, built from the English, Urdu, and Roman Urdu lines.
A question can match that rule without repeating its words.
"""

import logging
import threading
from pathlib import Path

import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CACHE_PATH = PROJECT_ROOT / ".cache" / "handbook-mpnet.npz"
MODEL_NAME = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"

_lock = threading.Lock()
_model = None
_ready = False
_failed = False

log = logging.getLogger(__name__)


def passage_text(entry: dict) -> str:
    parts = [entry.get("q", ""), entry.get("uq", ""), entry.get("rq", ""), entry.get("answer", "")]
    return "\n".join(part.strip() for part in parts if part and part.strip())


def _embedder():
    global _model, _failed
    if _model is not None or _failed:
        return _model
    with _lock:
        if _model is None and not _failed:
            try:
                from fastembed import TextEmbedding

                _model = TextEmbedding(MODEL_NAME)
            except Exception:
                _failed = True
                log.exception("Handbook embeddings are unavailable. Word search will be used.")
    return _model


def _matrix(entries: list[dict], stamp: int) -> np.ndarray | None:
    ids = [entry["id"] for entry in entries]
    model = _embedder()
    if model is None:
        return None
    if CACHE_PATH.exists():
        saved = np.load(CACHE_PATH, allow_pickle=False)
        saved_ids = [str(item) for item in saved["ids"]]
        if int(saved["stamp"]) == stamp and saved_ids == ids:
            return np.asarray(saved["vectors"], dtype=np.float32)
    rows = [np.asarray(vector, dtype=np.float32) for vector in model.embed([passage_text(entry) for entry in entries])]
    matrix = np.vstack(rows)
    norms = np.linalg.norm(matrix, axis=1, keepdims=True)
    matrix = matrix / np.clip(norms, 1e-9, None)
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    np.savez(CACHE_PATH, stamp=np.int64(stamp), ids=np.array(ids), vectors=matrix)
    return matrix


def semantic_scores(message: str, entries: list[dict], stamp: int) -> dict[str, float]:
    """Cosine similarity of the question to every rule. Empty if the model cannot load."""
    text = " ".join(message.split())
    if not text or not entries:
        return {}
    try:
        matrix = _matrix(entries, stamp)
        model = _embedder()
        if matrix is None or model is None:
            return {}
        query = np.asarray(next(model.embed([text])), dtype=np.float32)
        query = query / max(float(np.linalg.norm(query)), 1e-9)
        scores = matrix @ query
    except Exception:
        log.exception("Handbook embedding search failed.")
        return {}
    return {entry["id"]: float(score) for entry, score in zip(entries, scores)}
