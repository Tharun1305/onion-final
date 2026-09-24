import sys
import torch
import timm
from PIL import Image
from torchvision import transforms
from ultralytics import YOLO

YOLO_MODEL_PATH = "runs/detect/results/yolo26s_onion-4/weights/best.pt"
EFFNET_MODEL_PATH = "models/efficientnetv2_s_multiclass_best.pth"

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

yolo_model = YOLO(YOLO_MODEL_PATH)

checkpoint = torch.load(EFFNET_MODEL_PATH, map_location=DEVICE)
classes = checkpoint["classes"]
image_size = checkpoint["image_size"]

effnet_model = timm.create_model(
    "tf_efficientnetv2_s.in21k_ft_in1k",
    pretrained=False,
    num_classes=len(classes)
)
effnet_model.load_state_dict(checkpoint["model_state_dict"])
effnet_model = effnet_model.to(DEVICE)
effnet_model.eval()

transform = transforms.Compose([
    transforms.Resize((image_size, image_size)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

def classify_crop(crop_image):
    tensor = transform(crop_image).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        output = effnet_model(tensor)
        probabilities = torch.softmax(output, dim=1)[0]
    prediction = probabilities.argmax().item()
    return classes[prediction], probabilities[prediction].item() * 100, probabilities

if len(sys.argv) < 2:
    print("Usage:")
    print("python detect_and_classify.py path_to_image")
    sys.exit()

image_path = sys.argv[1]
full_image = Image.open(image_path).convert("RGB")

results = yolo_model(image_path, conf=0.4)
boxes = results[0].boxes

if len(boxes) == 0:
    print("No onions detected in this image.")
    sys.exit()

print("\n==============================")
print(f"DETECTED {len(boxes)} ONION(S)")
print("==============================")

for idx, box in enumerate(boxes):
    x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
    conf = box.conf[0].item()

    crop = full_image.crop((x1, y1, x2, y2))
    class_name, confidence, all_probs = classify_crop(crop)

    print(f"\n--- Onion {idx + 1} ---")
    print(f"Box: ({x1}, {y1}) to ({x2}, {y2})   Detection confidence: {conf*100:.2f}%")
    print(f"Health prediction : {class_name}")
    print(f"Confidence         : {confidence:.2f}%")

    crop_save_path = f"results/crop_onion_{idx+1}.jpg"
    crop.save(crop_save_path)
    print(f"Saved crop to: {crop_save_path}")
