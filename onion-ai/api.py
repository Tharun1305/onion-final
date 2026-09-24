import os
import io
import tempfile
import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

# Register HEIC/HEIF phone image support for mobile phone uploads
try:
    import pillow_heif
    pillow_heif.register_heif_opener()
except ImportError:
    pass
from PIL import Image, ImageOps

# Import the existing inference logic directly from predict.py
from predict import predict_image, load_models

app = FastAPI(
    title="Onion AI Health Assessment API",
    description="Real-time Onion Health/Defect inference using trained YOLO + EfficientNetV2-S models.",
    version="1.0.0"
)

# Enable CORS for Flutter mobile/web/desktop
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Pre-load models on startup
@app.on_event("startup")
def startup_event():
    print("[API] Initializing AI models on startup...")
    load_models()
    print("[API] Models ready for inference.")

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
        raise HTTPException(status_code=400, detail="No image file provided. Use form field 'image' or 'file'.")

    contents = await upload.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Uploaded image file is empty.")

    filename = upload.filename or "unknown.jpg"
    content_type = upload.content_type or "image/jpeg"

    print("[API] request received")
    print(f"[API] filename: {filename}")
    print(f"[API] content type: {content_type}")
    print(f"[API] bytes received: {len(contents)}")

    # Normalize image to standardized RGB JPEG temporary file for the model
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
    try:
        try:
            # Decode JPEG/PNG/WEBP/HEIC/HEIF, orient with EXIF and convert to RGB
            pil_img = Image.open(io.BytesIO(contents))
            pil_img = ImageOps.exif_transpose(pil_img).convert("RGB")
            pil_img.save(temp_file.name, format="JPEG", quality=95)
            temp_file.close()
        except Exception as decode_err:
            print(f"[API] Direct image decode fallback: {decode_err}")
            temp_file.write(contents)
            temp_file.close()

        print(f"[API] temporary file: {temp_file.name}")
        print("[API] model inference started")

        # Call existing inference logic from predict.py
        result = predict_image(temp_file.name)
        print(f"[API] prediction: {result.get('prediction')}")
        print(f"[API] confidence: {result.get('confidence')}%")
        return result
    except Exception as e:
        print(f"[API] Inference error: {e}")
        raise HTTPException(status_code=500, detail=f"Inference error: {str(e)}")
    finally:
        # Clean up temporary file
        if os.path.exists(temp_file.name):
            try:
                os.remove(temp_file.name)
            except Exception:
                pass

if __name__ == "__main__":
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=False)
