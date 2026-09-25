import os
import io
import sys
import tempfile
import numpy as np
from PIL import Image, ImageOps

# Register HEIC/HEIF phone image decoder support
try:
    import pillow_heif  # type: ignore
    pillow_heif.register_heif_opener()
except Exception:
    pass

try:
    import onnxruntime as ort  # type: ignore
    HAS_ORT = True
except Exception:
    HAS_ORT = False

try:
    import torch  # type: ignore
    import timm  # type: ignore
    HAS_TORCH = True
except Exception:
    HAS_TORCH = False

# Classes matching the trained model exactly
CLASSES = ['black_rot', 'damaged', 'healthy', 'mold', 'soft_rot', 'sprouted']
IMAGE_SIZE = 384

# Preprocessing normalization matching train_multiclass.py / test_real.py
NORM_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
NORM_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)

class OnionModelService:
    def __init__(self):
        self.session = None
        self.torch_model = None
        self.predict_module = None
        self._init_model()

    def _init_model(self):
        # Resolve search directories across both onion-main/onion-main and onion-main
        current_dir = os.path.dirname(os.path.abspath(__file__))
        app_dir = os.path.dirname(current_dir)
        backend_dir = os.path.dirname(app_dir)
        inner_root = os.path.dirname(backend_dir)
        outer_root = os.path.dirname(inner_root)

        candidate_roots = [
            inner_root,
            outer_root,
            os.path.abspath(os.path.join(backend_dir, "..")),
            os.path.abspath(os.path.join(backend_dir, "..", "..")),
        ]

        # 1. Try to link directly to onion-ai/predict.py if available
        for root in candidate_roots:
            onion_ai_dir = os.path.join(root, "onion-ai")
            if os.path.exists(onion_ai_dir) and os.path.exists(os.path.join(onion_ai_dir, "predict.py")):
                try:
                    if onion_ai_dir not in sys.path:
                        sys.path.insert(0, onion_ai_dir)
                    import predict as p_mod  # type: ignore
                    p_mod.load_models()
                    self.predict_module = p_mod
                    print(f"[AI Service] Successfully linked to trained pipeline in {onion_ai_dir}")
                    return
                except Exception as e:
                    print(f"[AI Service] Note: Could not import onion-ai/predict.py: {e}")

        # 2. Try ONNX models
        onnx_candidates = []
        for root in candidate_roots:
            onnx_candidates.extend([
                os.path.join(root, "onion-ai", "models", "onion_efficientnetv2_standalone.onnx"),
                os.path.join(root, "onion-ai", "models", "onion_efficientnetv2.onnx"),
                os.path.join(root, "onion_app", "assets", "models", "onion_efficientnetv2.onnx"),
                os.path.join(root, "onion-main", "onion_app", "assets", "models", "onion_efficientnetv2.onnx"),
            ])

        if HAS_ORT:
            for p in onnx_candidates:
                if os.path.exists(p):
                    try:
                        self.session = ort.InferenceSession(p)
                        print(f"[AI Service] Loaded ONNX model from: {p}")
                        return
                    except Exception as e:
                        print(f"[AI Service] Failed loading ONNX {p}: {e}")

        # 3. Try PyTorch .pth model
        pth_candidates = []
        for root in candidate_roots:
            pth_candidates.extend([
                os.path.join(root, "onion-ai", "models", "efficientnetv2_s_multiclass_best.pth"),
                os.path.join(root, "models", "efficientnetv2_s_multiclass_best.pth"),
            ])

        if HAS_TORCH:
            for pth_path in pth_candidates:
                if os.path.exists(pth_path):
                    try:
                        ckpt = torch.load(pth_path, map_location="cpu")
                        model = timm.create_model("tf_efficientnetv2_s.in21k_ft_in1k", pretrained=False, num_classes=len(CLASSES))
                        model.load_state_dict(ckpt["model_state_dict"])
                        model.eval()
                        self.torch_model = model
                        print(f"[AI Service] Loaded PyTorch model from: {pth_path}")
                        return
                    except Exception as e:
                        print(f"[AI Service] Failed loading PyTorch model: {e}")

    def preprocess_image(self, image_bytes: bytes) -> np.ndarray:
        image = Image.open(io.BytesIO(image_bytes))
        image = ImageOps.exif_transpose(image).convert("RGB")
        # Resize to 384x384
        image = image.resize((IMAGE_SIZE, IMAGE_SIZE), Image.Resampling.BILINEAR)
        img_arr = np.array(image, dtype=np.float32) / 255.0
        # Normalize
        img_arr = (img_arr - NORM_MEAN) / NORM_STD
        # HWC to CHW -> (3, 384, 384) -> (1, 3, 384, 384)
        img_arr = np.transpose(img_arr, (2, 0, 1))
        return np.expand_dims(img_arr, axis=0).astype(np.float32)

    def predict(self, image_bytes: bytes) -> dict:
        # If predict.py module from onion-ai is loaded, use it directly
        if self.predict_module is not None:
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
            try:
                # Normalize EXIF and format
                pil_img = Image.open(io.BytesIO(image_bytes))
                pil_img = ImageOps.exif_transpose(pil_img).convert("RGB")
                pil_img.save(temp_file.name, format="JPEG", quality=95)
                temp_file.close()

                res = self.predict_module.predict_image(temp_file.name)
                if "detections" not in res:
                    detections = []
                    if res.get("detected_onion") and res.get("box"):
                        detections.append({
                            "class_name": "onion",
                            "confidence": (res.get("detection_confidence") or 88.0) / 100.0,
                            "box": res["box"]
                        })
                    res["detections"] = detections
                    res["detections_count"] = len(detections)
                if "confidence_percentage" not in res:
                    res["confidence_percentage"] = f"{res['confidence']:.1f}%"
                return res
            finally:
                if os.path.exists(temp_file.name):
                    try:
                        os.remove(temp_file.name)
                    except Exception:
                        pass

        tensor = self.preprocess_image(image_bytes)

        if self.session is not None:
            input_name = self.session.get_inputs()[0].name
            ort_outs = self.session.run(None, {input_name: tensor})
            logits = ort_outs[0][0]
        elif self.torch_model is not None:
            with torch.no_grad():
                t = torch.from_numpy(tensor)
                out = self.torch_model(t)
                logits = out[0].numpy()
        else:
            raise RuntimeError("No model is loaded in OnionModelService. Verify onion-ai or ONNX model files.")

        # Softmax
        exp_logits = np.exp(logits - np.max(logits))
        probabilities = exp_logits / np.sum(exp_logits)

        best_idx = int(np.argmax(probabilities))
        best_class = CLASSES[best_idx]
        confidence = float(probabilities[best_idx]) * 100.0

        all_probs = {cls_name: round(float(probabilities[i]) * 100.0, 2) for i, cls_name in enumerate(CLASSES)}

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
            "prediction": best_class,
            "prediction_display": display_names.get(best_class, best_class.title()),
            "confidence": round(confidence, 2),
            "confidence_percentage": f"{confidence:.1f}%",
            "status": "Healthy" if best_class == "healthy" else "Defective",
            "is_low_confidence": confidence < 60.0,
            "probabilities": all_probs,
            "classes": CLASSES,
            "detected_onion": True,
            "detection_confidence": round(confidence, 2),
            "detections_count": 1,
            "detections": [{
                "class_name": "onion",
                "confidence": round(confidence / 100.0, 3),
                "box": [0, 0, IMAGE_SIZE, IMAGE_SIZE]
            }],
            "box": [0, 0, IMAGE_SIZE, IMAGE_SIZE],
        }

ai_model_service = OnionModelService()
6