import os
import torch
import timm
import numpy as np
import cv2
from PIL import Image
from torchvision import transforms

MODEL_PATH="models/efficientnetv2_s_best.pth"
INPUT_DIR="real_test/healthy"
OUTPUT_DIR="results/gradcam"

os.makedirs(OUTPUT_DIR,exist_ok=True)

DEVICE=torch.device("cuda" if torch.cuda.is_available() else "cpu")
IMAGE_SIZE=384

transform=transforms.Compose([
    transforms.Resize((IMAGE_SIZE,IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225])
])

checkpoint=torch.load(MODEL_PATH,map_location=DEVICE)

model=timm.create_model(
    "tf_efficientnetv2_s.in21k_ft_in1k",
    pretrained=False,
    num_classes=2
)

model.load_state_dict(checkpoint["model_state_dict"])
model=model.to(DEVICE)
model.eval()

target_layer=model.conv_head

def generate_gradcam(image_path):

    image=Image.open(image_path).convert("RGB")
    original=np.array(image)

    tensor=transform(image).unsqueeze(0).to(DEVICE)
    tensor.requires_grad=True

    activations=None
    gradients=None

    def forward_hook(module,input,output):
        nonlocal activations
        activations=output

    def backward_hook(module,grad_input,grad_output):
        nonlocal gradients
        gradients=grad_output[0]

    h1=target_layer.register_forward_hook(forward_hook)
    h2=target_layer.register_full_backward_hook(backward_hook)

    output=model(tensor)
    predicted=output.argmax(1).item()

    model.zero_grad()
    output[0,predicted].backward()

    h1.remove()
    h2.remove()

    weights=gradients.mean(dim=(2,3),keepdim=True)

    cam=(weights*activations).sum(dim=1).squeeze().detach().cpu().numpy()

    cam=np.maximum(cam,0)

    if cam.max()>0:
        cam=cam/cam.max()

    cam=cv2.resize(
        cam,
        (original.shape[1],original.shape[0])
    )

    heatmap=cv2.applyColorMap(
        np.uint8(255*cam),
        cv2.COLORMAP_JET
    )

    original_bgr=cv2.cvtColor(
        original,
        cv2.COLOR_RGB2BGR
    )

    overlay=cv2.addWeighted(
        original_bgr,
        0.5,
        heatmap,
        0.5,
        0
    )

    name=os.path.splitext(
        os.path.basename(image_path)
    )[0]

    output_path=os.path.join(
        OUTPUT_DIR,
        name+"_gradcam.jpg"
    )

    cv2.imwrite(output_path,overlay)

    print(
        os.path.basename(image_path),
        "| Predicted:",
        "UNHEALTHY" if predicted==1 else "HEALTHY",
        "| Saved:",
        output_path
    )

for file in os.listdir(INPUT_DIR):

    path=os.path.join(INPUT_DIR,file)

    try:
        generate_gradcam(path)
    except Exception as e:
        print("ERROR:",file,e)

print("\nDONE")