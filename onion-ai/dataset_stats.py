import os
from collections import Counter
from PIL import Image

ROOT="dataset/raw"
CLASSES=["healthy","unhealthy"]
EXTENSIONS=(".jpg",".jpeg",".png",".webp",".bmp")

for cls in CLASSES:
    folder=os.path.join(ROOT,cls)

    files=[
        f for f in os.listdir(folder)
        if f.lower().endswith(EXTENSIONS)
    ]

    prefix_counts=Counter()

    for f in files:
        name=f.lower()

        if name.startswith("aug_"):
            prefix_counts["aug_"]=prefix_counts["aug_"]+1
        elif name.startswith("img_"):
            prefix_counts["img_"]=prefix_counts["img_"]+1
        else:
            prefix_counts["other"]=prefix_counts["other"]+1

    print("\n==============================")
    print(cls.upper())
    print("==============================")
    print("Total:",len(files))
    print("aug_ :",prefix_counts["aug_"])
    print("img_ :",prefix_counts["img_"])
    print("other:",prefix_counts["other"])

    sizes=Counter()

    for f in files:
        path=os.path.join(folder,f)

        try:
            with Image.open(path) as img:
                sizes[img.size]+=1
        except:
            pass

    print("\nTop image sizes:")

    for size,count in sizes.most_common(10):
        print(size,":",count)