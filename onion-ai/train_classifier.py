import os
import copy
import torch
import timm
import numpy as np
from PIL import Image
from tqdm import tqdm
from torchvision import datasets,transforms
from torch.utils.data import DataLoader
from sklearn.metrics import accuracy_score,precision_score,recall_score,f1_score,confusion_matrix

DATASET="dataset"
MODEL_DIR="models"
RESULT_DIR="results"

os.makedirs(MODEL_DIR,exist_ok=True)
os.makedirs(RESULT_DIR,exist_ok=True)

DEVICE=torch.device("cuda" if torch.cuda.is_available() else "cpu")

IMAGE_SIZE=384
BATCH_SIZE=16
EPOCHS=30
NUM_WORKERS=0
LR=3e-4
WEIGHT_DECAY=1e-4
PATIENCE=7

train_transform=transforms.Compose([
    transforms.Resize((IMAGE_SIZE,IMAGE_SIZE)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomVerticalFlip(),
    transforms.RandomRotation(15),
    transforms.ColorJitter(brightness=0.15,contrast=0.15,saturation=0.15),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225])
])

eval_transform=transforms.Compose([
    transforms.Resize((IMAGE_SIZE,IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225])
])

train_data=datasets.ImageFolder(os.path.join(DATASET,"train"),transform=train_transform)
val_data=datasets.ImageFolder(os.path.join(DATASET,"validation"),transform=eval_transform)
test_data=datasets.ImageFolder(os.path.join(DATASET,"test"),transform=eval_transform)

train_loader=DataLoader(train_data,batch_size=BATCH_SIZE,shuffle=True,num_workers=NUM_WORKERS,pin_memory=True)
val_loader=DataLoader(val_data,batch_size=BATCH_SIZE,shuffle=False,num_workers=NUM_WORKERS,pin_memory=True)
test_loader=DataLoader(test_data,batch_size=BATCH_SIZE,shuffle=False,num_workers=NUM_WORKERS,pin_memory=True)

print("Classes:",train_data.classes)
print("Train:",len(train_data))
print("Validation:",len(val_data))
print("Test:",len(test_data))
print("Device:",DEVICE)

counts=np.bincount(train_data.targets)
weights=len(train_data)/(len(counts)*counts)
class_weights=torch.tensor(weights,dtype=torch.float32,device=DEVICE)

model=timm.create_model(
    "tf_efficientnetv2_s.in21k_ft_in1k",
    pretrained=True,
    num_classes=2
)

model=model.to(DEVICE)

criterion=torch.nn.CrossEntropyLoss(weight=class_weights)

optimizer=torch.optim.AdamW(
    model.parameters(),
    lr=LR,
    weight_decay=WEIGHT_DECAY
)

scheduler=torch.optim.lr_scheduler.CosineAnnealingLR(
    optimizer,
    T_max=EPOCHS
)

scaler=torch.amp.GradScaler("cuda")

best_f1=0
best_state=None
patience_counter=0

for epoch in range(EPOCHS):
    model.train()

    train_loss=0
    train_preds=[]
    train_labels=[]

    progress=tqdm(train_loader,desc=f"Epoch {epoch+1}/{EPOCHS}")

    for images,labels in progress:
        images=images.to(DEVICE,non_blocking=True)
        labels=labels.to(DEVICE,non_blocking=True)

        optimizer.zero_grad(set_to_none=True)

        with torch.amp.autocast("cuda"):
            outputs=model(images)
            loss=criterion(outputs,labels)

        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()

        train_loss+=loss.item()*images.size(0)

        preds=outputs.argmax(1)

        train_preds.extend(preds.detach().cpu().numpy())
        train_labels.extend(labels.detach().cpu().numpy())

        progress.set_postfix(loss=f"{loss.item():.4f}")

    scheduler.step()

    train_loss/=len(train_data)

    model.eval()

    val_preds=[]
    val_labels=[]
    val_loss=0

    with torch.no_grad():
        for images,labels in val_loader:
            images=images.to(DEVICE,non_blocking=True)
            labels=labels.to(DEVICE,non_blocking=True)

            with torch.amp.autocast("cuda"):
                outputs=model(images)
                loss=criterion(outputs,labels)

            val_loss+=loss.item()*images.size(0)

            preds=outputs.argmax(1)

            val_preds.extend(preds.cpu().numpy())
            val_labels.extend(labels.cpu().numpy())

    val_loss/=len(val_data)

    val_acc=accuracy_score(val_labels,val_preds)
    val_precision=precision_score(val_labels,val_preds,average="binary",zero_division=0)
    val_recall=recall_score(val_labels,val_preds,average="binary",zero_division=0)
    val_f1=f1_score(val_labels,val_preds,average="binary",zero_division=0)

    print(
        f"\nEpoch {epoch+1}: "
        f"train_loss={train_loss:.4f} "
        f"val_loss={val_loss:.4f} "
        f"val_acc={val_acc:.4f} "
        f"val_precision={val_precision:.4f} "
        f"val_recall={val_recall:.4f} "
        f"val_f1={val_f1:.4f}"
    )

    if val_f1>best_f1:
        best_f1=val_f1
        best_state=copy.deepcopy(model.state_dict())
        patience_counter=0

        torch.save(
            {
                "model_state_dict":best_state,
                "classes":train_data.classes,
                "image_size":IMAGE_SIZE
            },
            os.path.join(MODEL_DIR,"efficientnetv2_s_best.pth")
        )

        print("Best model saved.")

    else:
        patience_counter+=1

    if patience_counter>=PATIENCE:
        print("Early stopping.")
        break

if best_state is not None:
    model.load_state_dict(best_state)

model.eval()

test_preds=[]
test_labels=[]

with torch.no_grad():
    for images,labels in test_loader:
        images=images.to(DEVICE,non_blocking=True)

        outputs=model(images)
        preds=outputs.argmax(1)

        test_preds.extend(preds.cpu().numpy())
        test_labels.extend(labels.numpy())

test_acc=accuracy_score(test_labels,test_preds)
test_precision=precision_score(test_labels,test_preds,average="binary",zero_division=0)
test_recall=recall_score(test_labels,test_preds,average="binary",zero_division=0)
test_f1=f1_score(test_labels,test_preds,average="binary",zero_division=0)

print("\n==============================")
print("FINAL TEST RESULTS")
print("==============================")
print(f"Accuracy : {test_acc:.4f}")
print(f"Precision: {test_precision:.4f}")
print(f"Recall   : {test_recall:.4f}")
print(f"F1 Score : {test_f1:.4f}")
print("\nConfusion Matrix:")
print(confusion_matrix(test_labels,test_preds))