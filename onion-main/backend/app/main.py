import uvicorn
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timezone

from app.schemas import (
    LoginRequest,
    UserResponse,
    InspectionSyncRequest,
    SyncResponse,
    ReportSyncRequest,
    SyncStatusResponse,
)
from app.services.supabase_service import supabase_service
from app.services.ai_service import ai_model_service
from fastapi import UploadFile, File
import base64

app = FastAPI(
    title="AI Onion Quality Assessment & Grading API",
    description="FastAPI backend for offline-first mobile onion inspection sync and Supabase PostgreSQL persistence.",
    version="1.0.0",
)

# Enable CORS for Flutter mobile & web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r".*",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.options("/predict")
@app.options("/api/ai/predict")
def options_predict():
    return {}


@app.get("/")
def root():
    return {
        "service": "Onion Quality Assessment & Grading Backend",
        "version": "1.0.0",
        "status": "OPERATIONAL",
        "docs_url": "/docs",
    }

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "database": "connected" if supabase_service.is_connected else "local_fallback"
    }

@app.post("/auth/login", response_model=UserResponse)
def login(request: LoginRequest):
    """
    Authenticate inspector. For demo/MVP, accepts pre-seeded test credentials
    or valid inspector logins, returning a valid JWT-like session token.
    """
    valid_users = {
        "inspector.shinde": {"full_name": "Ramesh Shinde", "role": "Senior Quality Inspector", "center_id": "center-nashik-01"},
        "inspector.patil": {"full_name": "Sunita Patil", "role": "Quality Assessor", "center_id": "center-nashik-01"},
        "admin": {"full_name": "APMC Administrator", "role": "Super Admin", "center_id": "center-nashik-01"},
    }

    username = request.username.strip().lower()
    # Accept if recognized, or generic inspector
    user_info = valid_users.get(username, {
        "full_name": request.username.title().replace(".", " "),
        "role": "Procurement Inspector",
        "center_id": "center-nashik-01"
    })

    return UserResponse(
        id=f"user-{username}",
        username=username,
        full_name=user_info["full_name"],
        role=user_info["role"],
        center_id=user_info["center_id"],
        token=f"sess-token-{username}-{int(datetime.now().timestamp())}",
    )

@app.post("/inspections/sync", response_model=SyncResponse)
def sync_inspection(payload: InspectionSyncRequest):
    """
    Idempotent synchronization endpoint.
    Accepts full inspection payload with images, detections, validations, and grading.
    """
    try:
        data_dict = payload.model_dump()
        result = supabase_service.sync_inspection(data_dict)
        return SyncResponse(**result)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to synchronize inspection: {str(e)}"
        )

@app.get("/inspections")
def list_inspections():
    """Retrieve all synchronized inspections."""
    return supabase_service.get_inspections()

@app.get("/inspections/{inspection_id}")
def get_inspection_detail(inspection_id: str):
    """Retrieve an inspection by ID including its detections, validations, and grading."""
    insp = supabase_service.get_inspection_detail(inspection_id)
    if not insp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Inspection with ID {inspection_id} not found."
        )
    return insp

@app.post("/reports/sync")
def sync_report(payload: ReportSyncRequest):
    """Sync digital PDF report metadata."""
    try:
        return supabase_service.sync_report(payload.model_dump())
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to synchronize report: {str(e)}"
        )

@app.get("/sync/status", response_model=SyncStatusResponse)
def get_sync_status():
    """Returns cloud synchronization status and server timestamp."""
    return supabase_service.get_status()

@app.post("/predict")
@app.post("/api/ai/predict")
async def predict_onion(
    file: UploadFile = File(None),
    image: UploadFile = File(None)
):
    """
    Run inference on uploaded onion image using the trained onion AI model.
    Accepts either 'image' or 'file' form fields.
    Returns prediction, confidence %, and class probabilities for all 6 classes.
    """
    upload = image or file
    if upload is None:
        raise HTTPException(
            status_code=400,
            detail="Missing image file in request (send 'image' or 'file' as multipart form data)."
        )
    try:
        contents = await upload.read()
        if not contents:
            raise HTTPException(status_code=400, detail="Empty image file received.")
        result = ai_model_service.predict(contents)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Inference failure: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
