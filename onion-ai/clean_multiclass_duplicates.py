import os
import shutil
from PIL import Image
import imagehash

ROOT="dataset/multiclass"
QUARANTINE="dataset/multiclass_quarantine/duplicates"

EXTENSIONS={".jpg",".jpeg",".png",".webp",".bmp",".avif"}

os.makedirs(QUARANTINE,exist_ok=True)

hashes={}
duplicates=0

for class_name in sorted(os.listdir(ROOT)):
    class_path=os.path.join(ROOT,class_name)

    if not os.path.isdir(class_path):
        continue

    for filename in sorted(os.listdir(class_path)):
        path=os.path.join(class_path,filename)

        if not os.path.isfile(path):
            continue

        if os.path.splitext(filename)[1].lower() not in EXTENSIONS:
            continue

        try:
            img=Image.open(path).convert("RGB")
            h=str(imagehash.phash(img))
        except Exception:
            continue

        if h in hashes:
            original=hashes[h]

            destination=os.path.join(
                QUARANTINE,
                f"{class_name}__{filename}"
            )

            shutil.move(path,destination)

            print(f"MOVED: {class_name}/{filename}")
            print(f"  SAME AS: {original}")

            duplicates+=1
        else:
            hashes[h]=f"{class_name}/{filename}"

print("\n==============================")
print("DUPLICATE CLEANUP")
print("==============================")
print(f"Duplicates moved: {duplicates}")
print(f"Unique remaining : {len(hashes)}")