import os
import torch
import timm
from PIL import Image
from torchvision import transforms
from sklearn.metrics import accuracy_score,precision_score,recall_score,f1_score,confusion_matrix

MODEL_PATH="models/efficientnetv2_s_best.pth"
TEST_DIR="real_test"
IMAGE_SIZE=384

DEVICE=torch.device("cuda" if torch.cuda.is_available() else "cpu")

checkpoint=torch.load(MODEL_PATH,map_location=DEVICE)

model=timm.create_model(
    "tf_efficientnetv2_s.in21k_ft_in1k",
    pretrained=False,
    num_classes=2
)

model.load_state_dict(checkpoint["model_state_dict"])
model=model.to(DEVICE)
model.eval()

transform=transforms.Compose([
    transforms.Resize((IMAGE_SIZE,IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(
        [0.485,0.456,0.406],
        [0.229,0.224,0.225]
    )
])

classes=["healthy","unhealthy"]

true_labels=[]
pred_labels=[]

for actual_class in classes:
    folder=os.path.join(TEST_DIR,actual_class)

    for file in sorted(os.listdir(folder)):
        if not file.lower().endswith((".jpg",".jpeg",".png",".webp",".avif")):
            continue

        path=os.path.join(folder,file)

        image=Image.open(path).convert("RGB")
        image=transform(image).unsqueeze(0).to(DEVICE)

        with torch.no_grad():
            output=model(image)
            probabilities=torch.softmax(output,dim=1)
            confidence,prediction=torch.max(probabilities,dim=1)

        actual=classes.index(actual_class)
        predicted=prediction.item()

        true_labels.append(actual)
        pred_labels.append(predicted)

        status="✓" if actual==predicted else "✗"

        print(
            f"{file} | "
            f"Actual: {actual_class.upper()} | "
            f"Predicted: {classes[predicted].upper()} | "
            f"Confidence: {confidence.item()*100:.2f}% | "
            f"{status}"
        )

accuracy=accuracy_score(true_labels,pred_labels)
precision=precision_score(true_labels,pred_labels,average="binary",zero_division=0)
recall=recall_score(true_labels,pred_labels,average="binary",zero_division=0)
f1=f1_score(true_labels,pred_labels,average="binary",zero_division=0)

print("\n==============================")
print("REAL-WORLD TEST RESULTS")
print("==============================")
print(f"Images   : {len(true_labels)}")
print(f"Accuracy : {accuracy:.4f}")
print(f"Precision: {precision:.4f}")
print(f"Recall   : {recall:.4f}")
print(f"F1 Score : {f1:.4f}")

print("\nConfusion Matrix:")
print(confusion_matrix(true_labels,pred_labels))