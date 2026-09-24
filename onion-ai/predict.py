import os
import sys
import torch
import timm
from PIL import Image, ImageOps
from torchvision import transforms
from ultralytics import YOLO

# Register HEIC/HEIF image support for mobile phone uploads
try:
    import pillow_heif
    pillow_heif.register_heif_opener()
except ImportError:
    pass

# ---- Paths (Resolved relative to this script) ----
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
YOLO_MODEL_PATH = os.path.join(BASE_DIR, "runs", "detect", "results", "yolo26s_onion-4", "weights", "best.pt")
EFFNET_MODEL_PATH = os.path.join(BASE_DIR, "models", "efficientnetv2_s_multiclass_best.pth")

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ---- Global Model Cache ----
_yolo_model = None
_effnet_model = None
_classes = None
_image_size = 384
_transform = None

def load_models():
    global _yolo_model, _effnet_model, _classes, _image_size, _transform

    if _effnet_model is not None and _yolo_model is not None:
        return _yolo_model, _effnet_model, _classes, _transform

    print(f"[predict.py] Loading models on device: {DEVICE}")

    # Load YOLO
    if os.path.exists(YOLO_MODEL_PATH):
        _yolo_model = YOLO(YOLO_MODEL_PATH)
        print(f"[predict.py] Loaded YOLO detector from: {YOLO_MODEL_PATH}")
    else:
        print(f"[predict.py] Warning: YOLO weights not found at: {YOLO_MODEL_PATH}")

    # Load EfficientNet multiclass checkpoint
    if os.path.exists(EFFNET_MODEL_PATH):
        checkpoint = torch.load(EFFNET_MODEL_PATH, map_location=DEVICE)
        _classes = checkpoint["classes"]
        _image_size = checkpoint["image_size"]

        model = timm.create_model(
            "tf_efficientnetv2_s.in21k_ft_in1k",
            pretrained=False,
            num_classes=len(_classes)
        )
        model.load_state_dict(checkpoint["model_state_dict"])
        model = model.to(DEVICE)
        model.eval()
        _effnet_model = model
        print(f"[predict.py] Loaded EfficientNet from: {EFFNET_MODEL_PATH} (Classes: {_classes})")
    else:
        raise FileNotFoundError(f"EfficientNet model checkpoint not found at: {EFFNET_MODEL_PATH}")

    _transform = transforms.Compose([
        transforms.Resize((_image_size, _image_size)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    return _yolo_model, _effnet_model, _classes, _transform

def classify_crop(crop_image):
    _, effnet, classes, transform = load_models()
    tensor = transform(crop_image).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        output = effnet(tensor)
        probabilities = torch.softmax(output, dim=1)[0]
    prediction = probabilities.argmax().item()
    return classes[prediction], probabilities[prediction].item() * 100, probabilities

def predict_image(image_path_or_pil):
    """
    Main inference entrypoint.
    Accepts image path or PIL.Image.
    Runs YOLO detector first. If detected, crops the onion and classifies.
    If no detector box (or detector unavailable), classifies the full/center frame directly.
    """
    yolo, _, classes, _ = load_models()

    if isinstance(image_path_or_pil, str):
        full_image = Image.open(image_path_or_pil)
        full_image = ImageOps.exif_transpose(full_image).convert("RGB")
        img_source = image_path_or_pil
    else:
        full_image = ImageOps.exif_transpose(image_path_or_pil).convert("RGB")
        img_source = full_image

    boxes = []
    box_coords = None
    yolo_conf = 0.0

    if yolo is not None:
        try:
            results = yolo(img_source, conf=0.35, verbose=False)
            boxes = results[0].boxes
        except Exception as e:
            print(f"[predict.py] YOLO detection warning: {e}")
            boxes = []

    if len(boxes) > 0:
        # Pick the most confident detected onion
        best_box = max(boxes, key=lambda b: b.conf[0].item())
        x1, y1, x2, y2 = map(int, best_box.xyxy[0].tolist())
        yolo_conf = float(best_box.conf[0].item())
        box_coords = [x1, y1, x2, y2]
        crop = full_image.crop((x1, y1, x2, y2))
    else:
        # Fallback to full frame / center crop if onion fills the frame
        crop = full_image

    class_name, confidence, all_probs = classify_crop(crop)

    prob_dict = {
        classes[i]: round(float(all_probs[i].item()) * 100.0, 2)
        for i in range(len(classes))
    }

    display_names = {
        'healthy': 'Healthy',
        'damaged': 'Damaged',
        'black_rot': 'Black Rot',
        'mold': 'Mold',
        'soft_rot': 'Soft Rot',
        'sprouted': 'Sprouted'
    }

    return {
        "success": True,
        "prediction": class_name,
        "prediction_display": display_names.get(class_name, class_name.title()),
        "confidence": round(confidence, 2),
        "status": "Healthy" if class_name == "healthy" else "Defective",
        "probabilities": prob_dict,
        "classes": classes,
        "detected_onion": len(boxes) > 0,
        "detection_confidence": round(yolo_conf * 100.0, 2) if len(boxes) > 0 else None,
        "box": box_coords
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("python predict.py path_to_image")
        sys.exit()

    image_path = sys.argv[1]
    res = predict_image(image_path)

    print("\n==============================")
    print(f"HEALTH PREDICTION: {res['prediction_display']}")
    print(f"CONFIDENCE       : {res['confidence']}%")
    print(f"STATUS           : {res['status']}")
    print("==============================")
    print("PROBABILITIES:")
    for c, p in res["probabilities"].items():
        print(f"  {c:12}: {p:.2f}%")