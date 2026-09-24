import os
import math
import random
from PIL import Image,ImageDraw,ImageFont

ROOT="dataset/multiclass"
OUT="results/multiclass_labeled_preview.jpg"

classes=["healthy","black_rot","mold","soft_rot","sprouted","damaged"]

THUMB=160
LABEL_H=45
COLS=5
PER_CLASS=30

font=ImageFont.load_default()

rows_per_class=math.ceil(PER_CLASS/COLS)
height=len(classes)*rows_per_class*(THUMB+LABEL_H+25)

canvas=Image.new("RGB",(COLS*THUMB,height),"white")
draw=ImageDraw.Draw(canvas)

random.seed(42)

for class_index,class_name in enumerate(classes):

    folder=os.path.join(ROOT,class_name)

    files=[
        f for f in os.listdir(folder)
        if os.path.isfile(os.path.join(folder,f))
    ]

    random.shuffle(files)
    files=files[:PER_CLASS]

    base_y=class_index*rows_per_class*(THUMB+LABEL_H+25)

    draw.text((5,base_y),class_name,fill="black",font=font)

    for i,filename in enumerate(files):

        path=os.path.join(folder,filename)

        try:
            img=Image.open(path).convert("RGB")
            img.thumbnail((THUMB,THUMB))

            x=(i%COLS)*THUMB
            y=base_y+20+(i//COLS)*(THUMB+LABEL_H+5)

            cell=Image.new("RGB",(THUMB,THUMB),"white")

            px=(THUMB-img.width)//2
            py=(THUMB-img.height)//2

            cell.paste(img,(px,py))

            canvas.paste(cell,(x,y))

            name=filename[:24]

            draw.text(
                (x,y+THUMB+2),
                name,
                fill="black",
                font=font
            )

        except Exception:
            pass

os.makedirs("results",exist_ok=True)
canvas.save(OUT,quality=95)

print(f"Saved: {OUT}")