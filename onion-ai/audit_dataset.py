import os
from PIL import Image
import imagehash

ROOT="dataset/raw"
CLASSES=["healthy","unhealthy"]
EXTENSIONS=(".jpg",".jpeg",".png",".webp",".bmp")

total=0
valid=0
invalid=0
duplicates=0

hashes={}
invalid_files=[]
duplicate_files=[]

for cls in CLASSES:
    folder=os.path.join(ROOT,cls)

    print(f"\nChecking: {cls}")

    if not os.path.exists(folder):
        print(f"Folder not found: {folder}")
        continue

    files=[
        f for f in os.listdir(folder)
        if f.lower().endswith(EXTENSIONS)
    ]

    print(f"Images found: {len(files)}")

    for filename in files:
        path=os.path.join(folder,filename)
        total+=1

        try:
            with Image.open(path) as img:
                img.verify()

            with Image.open(path) as img:
                img=img.convert("RGB")
                h=str(imagehash.phash(img))

            valid+=1

            if h in hashes:
                duplicates+=1
                duplicate_files.append((path,hashes[h]))
            else:
                hashes[h]=path

        except Exception:
            invalid+=1
            invalid_files.append(path)

print("\n==============================")
print("DATASET AUDIT")
print("==============================")
print(f"Total images      : {total}")
print(f"Valid images      : {valid}")
print(f"Invalid images    : {invalid}")
print(f"Duplicates        : {duplicates}")
print("==============================")

if invalid_files:
    print("\nINVALID FILES:")
    for file in invalid_files:
        print(file)

if duplicate_files:
    print("\nDUPLICATES:")
    for duplicate,original in duplicate_files:
        print(f"\nDuplicate : {duplicate}")
        print(f"Original  : {original}")