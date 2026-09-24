import os
from PIL import Image
import imagehash

ROOT="dataset/multiclass"
EXTENSIONS={".jpg",".jpeg",".png",".webp",".bmp",".avif"}

hashes={}
total=0
valid=0
invalid=0
duplicates=0

for class_name in sorted(os.listdir(ROOT)):
    class_path=os.path.join(ROOT,class_name)

    if not os.path.isdir(class_path):
        continue

    print(f"\n[{class_name}]")

    count=0

    for filename in sorted(os.listdir(class_path)):
        path=os.path.join(class_path,filename)

        if not os.path.isfile(path):
            continue

        ext=os.path.splitext(filename)[1].lower()

        if ext not in EXTENSIONS:
            continue

        total+=1

        try:
            img=Image.open(path)
            img.verify()

            img=Image.open(path).convert("RGB")
            h=str(imagehash.phash(img))

            if h in hashes:
                print(f"DUPLICATE: {filename} <-> {hashes[h]}")
                duplicates+=1
            else:
                hashes[h]=f"{class_name}/{filename}"

            valid+=1
            count+=1

        except Exception as e:
            print(f"INVALID: {class_name}/{filename} -> {e}")
            invalid+=1

    print(f"Valid: {count}")

print("\n==============================")
print("MULTICLASS DATASET AUDIT")
print("==============================")
print(f"Total images : {total}")
print(f"Valid        : {valid}")
print(f"Invalid      : {invalid}")
print(f"Duplicates   : {duplicates}")
print(f"Unique       : {len(hashes)}")