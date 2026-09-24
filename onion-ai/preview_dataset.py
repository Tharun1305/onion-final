import os
import random
from PIL import Image,ImageDraw,ImageFont

ROOT="dataset/raw"
OUT="results/dataset_preview.jpg"

CLASSES=["healthy","unhealthy"]
SAMPLES_PER_CLASS=40
THUMB_W=220
THUMB_H=220
LABEL_H=40
COLS=5

font=ImageFont.load_default()

all_images={}

for cls in CLASSES:
    folder=os.path.join(ROOT,cls)

    files=[
        f for f in os.listdir(folder)
        if f.lower().endswith((".jpg",".jpeg",".png",".webp",".bmp"))
    ]

    random.seed(42)
    selected=random.sample(
        files,
        min(SAMPLES_PER_CLASS,len(files))
    )

    all_images[cls]=selected

rows=SAMPLES_PER_CLASS//COLS
width=COLS*THUMB_W
height=rows*(THUMB_H+LABEL_H)*len(CLASSES)

sheet=Image.new("RGB",(width,height),"white")
draw=ImageDraw.Draw(sheet)

y_offset=0

for cls in CLASSES:

    for i,filename in enumerate(all_images[cls]):

        path=os.path.join(ROOT,cls,filename)

        try:
            img=Image.open(path).convert("RGB")
            img.thumbnail((THUMB_W-10,THUMB_H-10))

            x=(i%COLS)*THUMB_W
            y=y_offset+(i//COLS)*(THUMB_H+LABEL_H)

            cell=Image.new("RGB",(THUMB_W,THUMB_H),"white")

            px=(THUMB_W-img.width)//2
            py=(THUMB_H-img.height)//2

            cell.paste(img,(px,py))

            sheet.paste(cell,(x,y))

            draw.text(
                (x+5,y+THUMB_H+5),
                f"{cls}: {filename[:25]}",
                fill="black",
                font=font
            )

        except Exception:
            pass

    y_offset+=rows*(THUMB_H+LABEL_H)

os.makedirs("results",exist_ok=True)

sheet.save(OUT,quality=95)

print(f"Preview saved to: {OUT}")