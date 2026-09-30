import os
import io
import tempfile
import time

from typing import Optional, Dict, Any

from fastapi import FastAPI, File, UploadFile, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, ImageOps
from pydantic import BaseModel

from predict import predict_image
from auth_service import auth_service


app = FastAPI(
    title="Onion AI Health Assessment API",
    description="Real-time Onion Health/Defect inference using trained YOLO + EfficientNetV2-S models.",
    version="1.0.0"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


@app.on_event("startup")
def startup_event():
    print("[API] Server starting without loading AI models.")
    print("[API] AI models will be loaded only when prediction is requested.")


@app.get("/")
def root():
    return {
        "status": "ok",
        "service": "onion-ai"
    }


@app.options("/predict")
async def options_predict():
    return {"status": "ok"}


@app.post("/predict")
async def predict(
    image: Optional[UploadFile] = File(None),
    file: Optional[UploadFile] = File(None),
):
    upload = image or file

    if upload is None:
        raise HTTPException(
            status_code=400,
            detail="No image file provided. Use form field 'image' or 'file'."
        )

    contents = await upload.read()

    if not contents:
        raise HTTPException(
            status_code=400,
            detail="Uploaded image file is empty."
        )

    filename = upload.filename or "unknown.jpg"
    content_type = upload.content_type or "image/jpeg"

    print("[API] Request received")
    print(f"[API] Filename: {filename}")
    print(f"[API] Content type: {content_type}")
    print(f"[API] Bytes received: {len(contents)}")

    temp_file = tempfile.NamedTemporaryFile(
        delete=False,
        suffix=".jpg"
    )

    try:
        try:
            pil_img = Image.open(io.BytesIO(contents))
            pil_img = ImageOps.exif_transpose(pil_img).convert("RGB")
            pil_img.save(
                temp_file.name,
                format="JPEG",
                quality=95
            )
            temp_file.close()

        except Exception as decode_err:
            print(f"[API] Direct image decode fallback: {decode_err}")

            temp_file.write(contents)
            temp_file.close()

        print(f"[API] Temporary file: {temp_file.name}")
        print("[API] Model inference started")

        result = predict_image(temp_file.name)

        print(f"[API] Prediction: {result.get('prediction')}")
        print(f"[API] Confidence: {result.get('confidence')}%")

        return result

    except Exception as e:
        print(f"[API] Inference error: {e}")

        raise HTTPException(
            status_code=500,
            detail=f"Inference error: {str(e)}"
        )

    finally:
        if os.path.exists(temp_file.name):
            try:
                os.remove(temp_file.name)
            except Exception:
                pass


# ==============================================================
# STATIC 5-ACCOUNT AUTHENTICATION & SESSION ENDPOINTS
# ==============================================================


class LoginRequest(BaseModel):
    username_or_email: Optional[str] = None
    username: Optional[str] = None
    email: Optional[str] = None
    password: str

    def get_identifier(self) -> str:
        return (
            self.username_or_email
            or self.email
            or self.username
            or ""
        ).strip()


class LogoutRequest(BaseModel):
    token: Optional[str] = None


def get_authenticated_user(
    authorization: Optional[str] = Header(None),
    token: Optional[str] = None
) -> Dict[str, Any]:

    auth_token = token

    if not auth_token and authorization:
        auth_token = authorization.replace(
            "Bearer ",
            ""
        ).strip()

    if not auth_token:
        raise HTTPException(
            status_code=401,
            detail="Authentication required"
        )

    user = auth_service.validate_session(auth_token)

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired session"
        )

    return user


@app.post("/auth/login")
def login_user(req: LoginRequest):

    identifier = req.get_identifier()

    if not identifier or not req.password:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    try:
        return auth_service.login(
            identifier,
            req.password
        )

    except ValueError:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    except Exception as e:
        print(f"[AUTH] Login error: {e}")

        raise HTTPException(
            status_code=500,
            detail="Authentication service error"
        )


@app.post("/auth/logout")
def logout_user(
    req: Optional[LogoutRequest] = None,
    authorization: Optional[str] = Header(None)
):

    token = None

    if req and req.token:
        token = req.token

    elif authorization:
        token = authorization.replace(
            "Bearer ",
            ""
        ).strip()

    if token:
        auth_service.logout(token)

    return {
        "status": "SUCCESS",
        "message": "Logged out successfully."
    }


@app.get("/auth/me")
def get_current_user(
    user: Dict[str, Any] = Depends(get_authenticated_user)
):
    return user


# ==============================================================
# USER-ASSOCIATED INSPECTION & REPORT ENDPOINTS
# ==============================================================


@app.post("/inspections/sync")
def sync_inspections(
    payload: Optional[Dict[str, Any]] = None,
    user: Dict[str, Any] = Depends(get_authenticated_user)
):

    if payload:
        auth_service.sync_user_inspection(
            user["id"],
            payload
        )

    return {
        "status": "SUCCESS",
        "message": "Inspection synchronized successfully for authenticated account.",
        "user_id": user["id"],
        "server_timestamp": time.time()
    }


@app.get("/inspections")
def list_user_inspections(
    user: Dict[str, Any] = Depends(get_authenticated_user)
):
    return auth_service.get_user_inspections(
        user["id"]
    )


@app.post("/reports/sync")
def sync_reports(
    payload: Optional[Dict[str, Any]] = None,
    user: Dict[str, Any] = Depends(get_authenticated_user)
):

    return {
        "status": "SUCCESS",
        "message": "Report synchronized successfully for account.",
        "user_id": user["id"]
    }


@app.get("/sync/status")
def sync_status():
    return {
        "status": "ONLINE",
        "server_timestamp": time.time()
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "api:app",
        host="0.0.0.0",
        port=8000,
        reload=False
    )