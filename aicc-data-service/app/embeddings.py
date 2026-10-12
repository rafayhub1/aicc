"""Vectors for the handbook rules.

The model loads in the background when the server starts. A chat request never
waits for that download, so Railway does not time out the question. Until the
model is ready, word search answers on its own.

paraphrase-multilingual-mpnet is about 1 GB and stalls a small Railway
instance. This MiniLM model is the same multilingual embedding search in a
size Railway can keep in memory.
"""

import logging
import os
import threading
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CACHE_DIR = PROJECT_ROOT / ".cache"
MODEL_CACHE = CACHE_DIR / "fastembed"
VECTOR_CACHE = CACHE_DIR / "handbook-minilm.npz"
MODEL_NAME = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"

_lock = threading.Lock()
_model = None
_ready = False
_matrix = None
_ids: list[str] = []
_stamp = -1

log = logging.getLogger(__name__)


def passage_text(entry: dict) -> str:
    parts = [entry.get("q", ""), entry.get("uq", ""), entry.get("rq", ""), entry.get("answer", "")]
    return "\n".join(part.strip() for part in parts if part and part.strip())


def warm_handbook(entries: list[dict], stamp: int) -> None:
    """Start loading the model. Returns immediately."""
    threading.Thread(
        target=_load,
        args=(entries, stamp),
        name="handbook-embeddings",
        daemon=True,
    ).start()


def _load(entries: list[dict], stamp: int) -> None:
    global _model, _ready, _matrix, _ids, _stamp
    try:
        import numpy as np
        from fastembed import TextEmbedding

        os.environ["FASTEMBED_CACHE_PATH"] = str(MODEL_CACHE)
        MODEL_CACHE.mkdir(parents=True, exist_ok=True)
        model = TextEmbedding(MODEL_NAME)
        matrix, ids = _vectors(model, entries, stamp, np)
        next(model.embed(["attendance"]))
        with _lock:
            _model = model
            _matrix = matrix
            _ids = ids
            _stamp = stamp
            _ready = True
        log.info("Handbook embeddings are ready (%s rules).", len(ids))
    except Exception:
        log.exception("Handbook embeddings are unavailable. Word search will be used.")


def _vectors(model, entries: list[dict], stamp: int, np):
    ids = [entry["id"] for entry in entries]
    if VECTOR_CACHE.exists():
        saved = np.load(VECTOR_CACHE, allow_pickle=False)
        saved_ids = [str(item) for item in saved["ids"]]
        if int(saved["stamp"]) == stamp and saved_ids == ids:
            return np.asarray(saved["vectors"], dtype=np.float32), ids
    rows = [
        np.asarray(vector, dtype=np.float32)
        for vector in model.embed([passage_text(entry) for entry in entries])
    ]
    matrix = np.vstack(rows)
    norms = np.linalg.norm(matrix, axis=1, keepdims=True)
    matrix = matrix / np.clip(norms, 1e-9, None)
    VECTOR_CACHE.parent.mkdir(parents=True, exist_ok=True)
    np.savez(VECTOR_CACHE, stamp=np.int64(stamp), ids=np.array(ids), vectors=matrix)
    return matrix, ids


def semantic_scores(message: str, entries: list[dict], stamp: int) -> dict[str, float]:
    """Cosine similarity of the question to every rule. Empty if the model is not ready."""
    text = " ".join(message.split())
    if not text or not entries:
        return {}
    with _lock:
        if not _ready or _model is None or _matrix is None or _stamp != stamp:
            return {}
        model = _model
        matrix = _matrix
        ids = list(_ids)
    try:
        import numpy as np

        query = np.asarray(next(model.embed([text])), dtype=np.float32)
        query = query / max(float(np.linalg.norm(query)), 1e-9)
        scores = matrix @ query
    except Exception:
        log.exception("Handbook embedding search failed.")
        return {}
    return {entry_id: float(score) for entry_id, score in zip(ids, scores)}
