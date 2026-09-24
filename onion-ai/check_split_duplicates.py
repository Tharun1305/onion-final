import os
from PIL import Image
import imagehash

ROOT="dataset"
SPLITS=["train","validation","test"]
CLASSES=["healthy","unhealthy"]
EXTENSIONS=(".jpg",".jpeg",".png",".webp",".bmp")

hashes={split:{} for split in SPLITS}

for split in SPLITS:
    for cls in CLASSES:
        path=os.path.join(ROOT,split,cls)

        for file in os.listdir(path):
            if not file.lower().endswith(EXTENSIONS):
                continue

            filepath=os.path.join(path,file)

            try:
                with Image.open(filepath) as img:
                    h=str(imagehash.phash(img))
                hashes[split][filepath]=(h,cls)
            except:
                pass

print("Checking cross-split similarity...\n")

threshold=4

for i in range(len(SPLITS)):
    for j in range(i+1,len(SPLITS)):
        split1=SPLITS[i]
        split2=SPLITS[j]

        matches=[]

        for file1,(hash1,cls1) in hashes[split1].items():
            h1=imagehash.hex_to_hash(hash1)

            for file2,(hash2,cls2) in hashes[split2].items():
                h2=imagehash.hex_to_hash(hash2)

                distance=h1-h2

                if distance<=threshold:
                    matches.append((file1,file2,distance,cls1,cls2))

        print(f"{split1.upper()} <-> {split2.upper()}: {len(matches)} matches")

        for m in matches[:10]:
            print(f"  distance={m[2]} | {m[3]} | {m[0]}")
            print(f"                       {m[4]} | {m[1]}")

print("\nDONE")