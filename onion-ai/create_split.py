import os
import shutil
import random

SEED=42
random.seed(SEED)

SOURCE="dataset/raw"
OUTPUT="dataset"

CLASSES=["healthy","unhealthy"]
EXTENSIONS=(".jpg",".jpeg",".png",".webp",".bmp")

for split in ["train","validation","test"]:
    for cls in CLASSES:
        folder=os.path.join(OUTPUT,split,cls)
        os.makedirs(folder,exist_ok=True)

        for file in os.listdir(folder):
            path=os.path.join(folder,file)
            if os.path.isfile(path):
                os.remove(path)

for cls in CLASSES:
    source_folder=os.path.join(SOURCE,cls)

    files=[
        f for f in os.listdir(source_folder)
        if f.lower().endswith(EXTENSIONS)
    ]

    files.sort()
    random.shuffle(files)

    n=len(files)

    train_count=int(n*0.70)
    validation_count=int(n*0.15)

    train_files=files[:train_count]
    validation_files=files[
        train_count:train_count+validation_count
    ]
    test_files=files[
        train_count+validation_count:
    ]

    splits={
        "train":train_files,
        "validation":validation_files,
        "test":test_files
    }

    print(f"\n{cls.upper()}")
    print(f"Total      : {n}")

    for split,split_files in splits.items():

        print(f"{split:<11}: {len(split_files)}")

        destination_folder=os.path.join(
            OUTPUT,
            split,
            cls
        )

        for file in split_files:
            shutil.copy2(
                os.path.join(source_folder,file),
                os.path.join(destination_folder,file)
            )

print("\n==============================")
print("DATASET SPLIT COMPLETE")
print("==============================")