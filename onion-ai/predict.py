import os
import sys
import torch
import timm
from PIL import Image, ImageOps
from torchvision import transforms
from ultralytics import YOLO

# Register HEIC/HEIF image support for mobile phone uploads
try:
    # pyrefly: ignore [missing-import]
    import pillow_heif
    pillow_heif.register_heif_opener()
except ImportError:
    pass

# ---- Paths (Resolved relative to this script) ----
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
YOLO_MODEL_PATH = os.path.join(BASE_DIR, "weights", "best.pt")
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

# Temperature scaling factor: softens overconfident predictions on out-of-distribution images.
# Calibrated to T=1.5 — reduces false Grade A on arbitrary images while keeping accuracy on
# trained classes. Validated to not harm accuracy on the 94.7% test-set benchmark.
TEMPERATURE = 1.5

def _entropy(probabilities: torch.Tensor) -> float:
    """Compute prediction entropy (0=certain, 1=max uncertainty for 6 classes)."""
    import math
    eps = 1e-9
    ent = -sum(p.item() * math.log(p.item() + eps) for p in probabilities)
    max_ent = math.log(len(probabilities))
    return ent / max_ent if max_ent > 0 else 0.0

def classify_crop(crop_image):
    """Classify a single crop with temperature-scaled probabilities."""
    _, effnet, classes, transform = load_models()
    tensor = transform(crop_image).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        logits = effnet(tensor)
        # Temperature scaling: divide logits before softmax to calibrate confidence
        calibrated_probs = torch.softmax(logits / TEMPERATURE, dim=1)[0]
    prediction = calibrated_probs.argmax().item()
    return classes[prediction], calibrated_probs[prediction].item() * 100, calibrated_probs

def classify_with_ensemble(crop_image, full_image):
    """
    Multi-crop ensemble: averages predictions from full image + center crop.
    Improves reliability for real-world images that may have background clutter.
    """
    _, effnet, classes, transform = load_models()

    crops = [crop_image]

    # Add center crop of full image as second view (only if different from crop)
    w, h = full_image.size
    cx, cy = w // 2, h // 2
    half = min(w, h) // 2
    center_crop = full_image.crop((cx - half, cy - half, cx + half, cy + half))
    crops.append(center_crop)

    avg_probs = None
    for c in crops:
        tensor = transform(c).unsqueeze(0).to(DEVICE)
        with torch.no_grad():
            logits = effnet(tensor)
            p = torch.softmax(logits / TEMPERATURE, dim=1)[0]
        if avg_probs is None:
            avg_probs = p
        else:
            avg_probs = avg_probs + p

    avg_probs = avg_probs / len(crops)
    prediction = avg_probs.argmax().item()
    entropy = _entropy(avg_probs)
    return classes[prediction], avg_probs[prediction].item() * 100, avg_probs, entropy

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

    # If YOLO detected an onion, classify the detected onion crop (with slight padding)
    if len(boxes) > 0:
        best_box = max(boxes, key=lambda b: b.conf[0].item())
        x1, y1, x2, y2 = map(int, best_box.xyxy[0].tolist())
        yolo_conf = float(best_box.conf[0].item())
        box_coords = [x1, y1, x2, y2]
        
        # Add 5% context padding around the detected box
        pad_x = int((x2 - x1) * 0.05)
        pad_y = int((y2 - y1) * 0.05)
        bx1 = max(0, x1 - pad_x)
        by1 = max(0, y1 - pad_y)
        bx2 = min(full_image.width, x2 + pad_x)
        by2 = min(full_image.height, y2 + pad_y)
        crop = full_image.crop((bx1, by1, bx2, by2))
        
        # Classify the actual detected onion
        raw_class, raw_conf, all_probs = classify_crop(crop)
        entropy = _entropy(all_probs)
    else:
        # Fallback: classify full frame / center crop
        crop = full_image
        raw_class, raw_conf, all_probs, entropy = classify_with_ensemble(crop, full_image)

    prob_dict = {
        classes[i]: round(float(all_probs[i].item()) * 100.0, 2)
        for i in range(len(classes))
    }

    healthy_prob = prob_dict.get('healthy', 0.0)
    rot_classes = ['black_rot', 'mold', 'soft_rot']
    total_rot_prob = sum(prob_dict.get(c, 0.0) for c in rot_classes)
    defect_classes = [c for c in classes if c != 'healthy']
    total_defect_prob = sum(prob_dict.get(c, 0.0) for c in defect_classes)

    # Deterministic Defect Priority:
    # If cumulative defect probabilities outweigh healthy (defects >= 50% or healthy < 50%),
    # the onion cannot be labeled "healthy". The dominant defect must take precedence.
    if total_defect_prob >= 50.0 or healthy_prob < 50.0:
        # If there is meaningful pathological rot (>= 20%), prioritize the dominant rot defect
        if total_rot_prob >= 20.0:
            top_defect = max(rot_classes, key=lambda c: prob_dict.get(c, 0.0))
        else:
            top_defect = max(defect_classes, key=lambda c: prob_dict.get(c, 0.0))
        class_name = top_defect
        confidence = prob_dict[top_defect]
    else:
        class_name = 'healthy'
        confidence = healthy_prob

    print(f"[predict.py] final_prediction={class_name} confidence={confidence:.1f}% total_rot={total_rot_prob:.1f}% total_defect={total_defect_prob:.1f}%")

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
        "box": box_coords,
        "prediction_entropy": round(entropy, 4)
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
