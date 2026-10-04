# AICC Dummy Data Service

FastAPI backend + admin UI for dummy student data stored in a **separate** Firebase project (`aicc-dummy-data`). Used by the AICC Flutter app for university demos.

## Local setup

```powershell
cd e:\FYP\aicc-data-service
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Copy `.env.example` to `.env` and set:

```
SERVICE_ACCOUNT_PATH=secrets/your-service-account-key.json
```

Verify Firebase:

```powershell
python scripts/check_firebase.py
```

Run the API:

```powershell
uvicorn app.main:app --reload
```

- Admin UI: http://127.0.0.1:8000/admin  
- API docs: http://127.0.0.1:8000/docs  

## Seed dummy data (72 students)

Creates 3 students per cohort (24 cohorts) with courses, notifications, and documents. **Idempotent** — safe to re-run.

```powershell
python scripts/seed_data.py
```

To replace everything (including manual test records):

```powershell
python scripts/seed_data.py --wipe
```

## Deploy to Render

1. Push this repo to GitHub (do **not** commit `secrets/` or `.env`).
2. [Render](https://render.com) → **New Web Service** → connect the repo.
3. Use `render.yaml` or set manually:
   - **Build:** `pip install -r requirements.txt`
   - **Start:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
4. Add environment variable **`GOOGLE_SERVICE_ACCOUNT_JSON`**: paste the **entire** service account JSON file contents (one line is fine).
5. Deploy. Open `https://your-service.onrender.com/admin`.

**Note:** Render free tier sleeps after ~15 minutes idle; first request may take ~50s. Warm the URL before a demo.

## API (mobile app)

Base URL: your Render URL or `http://127.0.0.1:8000` locally.

| Method | Path |
|--------|------|
| GET | `/api/catalog` |
| GET | `/api/students?department=&semester=&section=` |
| GET | `/api/students/{id}` |
| GET | `/api/students/{id}/courses?semester=` |
| GET | `/api/students/{id}/notifications` |
| GET | `/api/students/{id}/documents` |

Student document IDs equal `registrationNumber` (e.g. `FA26-BSCS-001`).
