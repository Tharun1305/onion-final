# Onion Quality Assessment & Grading — FastAPI Backend

This is the FastAPI cloud synchronization backend for the offline-first Onion Quality Assessment & Grading System.

## Features
- **Idempotent Synchronization**: Endpoints verify `client_sync_id` and unique `inspection_id` to prevent duplicates upon network retries.
- **Supabase Integration**: Native PostgreSQL persistence with full relational schema.
- **Resilient Standalone Fallback**: If Supabase credentials are not provided, automatically operates in-memory so mobile testing and offline sync validation function without external cloud dependencies.
- **Audit Trails**: Stores both original AI observations and Inspector corrections side-by-side.

## Setup Instructions

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure Environment (.env)
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Provide your Supabase URL and service role key if using a live Supabase instance:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
PORT=8000
HOST=0.0.0.0
```

### 3. Run the Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Interactive Swagger API docs available at: `http://localhost:8000/docs`.

## API Endpoints
- `GET /health`: Server health check.
- `POST /auth/login`: Inspector authentication.
- `POST /inspections/sync`: Idempotent inspection upload (images, detections, validations, grading).
- `GET /inspections`: List all synced inspections.
- `GET /inspections/{inspection_id}`: Full inspection details with audit trail.
- `POST /reports/sync`: Sync digital PDF report metadata.
- `GET /sync/status`: Server status, database connection, and sync counts.
