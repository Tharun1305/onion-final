import os
import shutil
from PIL import Image
import imagehash

ROOT="dataset/raw"
QUARANTINE="dataset/quarantine"
CLASSES=["healthy","unhealthy"]
EXTENSIONS=(".jpg",".jpeg",".png",".webp",".bmp")

os.makedirs(os.path.join(QUARANTINE,"healthy"),exist_ok=True)
os.makedirs(os.path.join(QUARANTINE,"unhealthy"),exist_ok=True)

hashes={}
duplicates=0
cross_class=0
same_class=0
invalid=0

for cls in CLASSES:
    folder=os.path.join(ROOT,cls)

    files=[
        f for f in os.listdir(folder)
        if f.lower().endswith(EXTENSIONS)
    ]

    for filename in files:
        path=os.path.join(folder,filename)

        try:
            with Image.open(path) as img:
                img=img.convert("RGB")
                h=str(imagehash.phash(img))

            if h in hashes:
                original_class,original_path=hashes[h]

                duplicates+=1

                if original_class!=cls:
                    cross_class+=1
                else:
                    same_class+=1

                destination=os.path.join(
                    QUARANTINE,
                    cls,
                    filename
                )

                shutil.move(path,destination)

                print("\nQUARANTINED")
                print("Duplicate :",path)
                print("Original  :",original_path)
                print("Type      :", "CROSS-CLASS" if original_class!=cls else "SAME-CLASS")

            else:
                hashes[h]=(cls,path)

        except Exception as e:
            invalid+=1
            print("\nINVALID:",path)
            print("Error:",e)

print("\n==============================")
print("CLEANING SUMMARY")
print("==============================")
print("Duplicates removed :",duplicates)
print("Cross-class        :",cross_class)
print("Same-class         :",same_class)
print("Invalid             :",invalid)
print("==============================")
print("\nOriginal images were NOT deleted.")
print("Duplicates were moved to dataset/quarantine/")