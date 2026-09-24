import os
from PIL import Image

ROOT="dataset"
SPLITS=["train","validation","test"]
CLASSES=["healthy","unhealthy"]
EXTENSIONS=(".jpg",".jpeg",".png",".webp",".bmp")

total=0
errors=0

for split in SPLITS:
    print(f"\n[{split.upper()}]")
    split_total=0

    for cls in CLASSES:
        path=os.path.join(ROOT,split,cls)
        count=0

        if not os.path.exists(path):
            print(f"{cls}: MISSING")
            errors+=1
            continue

        for file in os.listdir(path):
            if not file.lower().endswith(EXTENSIONS):
                continue

            filepath=os.path.join(path,file)

            try:
                with Image.open(filepath) as img:
                    img.verify()
                count+=1
            except Exception as e:
                print(f"ERROR: {filepath}")
                errors+=1

        print(f"{cls}: {count}")
        split_total+=count

    print(f"Total: {split_total}")
    total+=split_total

print("\n==============================")
print(f"TOTAL IMAGES: {total}")
print(f"ERRORS: {errors}")
print("==============================")

if errors==0:
    print("DATASET VERIFICATION: PASSED")
else:
    print("DATASET VERIFICATION: FAILED")