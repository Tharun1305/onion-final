import os
import shutil
import random
from PIL import Image
import imagehash

SOURCE="dataset/multiclass"
OUTPUT="dataset/multiclass_split"

CLASSES=[
    "healthy",
    "black_rot",
    "mold",
    "soft_rot",
    "sprouted",
    "damaged"
]

SEED=42
PHASH_THRESHOLD=4

random.seed(SEED)

for split in ["train","validation","test"]:
    for class_name in CLASSES:
        os.makedirs(
            os.path.join(OUTPUT,split,class_name),
            exist_ok=True
        )

files=[]
hashes=[]

for class_name in CLASSES:

    folder=os.path.join(SOURCE,class_name)

    for filename in os.listdir(folder):

        path=os.path.join(folder,filename)

        if not os.path.isfile(path):
            continue

        try:
            img=Image.open(path).convert("RGB")
            h=imagehash.phash(img)
        except:
            continue

        files.append((class_name,filename,path))
        hashes.append(h)

print("Images loaded:",len(files))

parent=list(range(len(files)))

def find(x):
    while parent[x]!=x:
        parent[x]=parent[parent[x]]
        x=parent[x]
    return x

def union(a,b):
    ra=find(a)
    rb=find(b)

    if ra!=rb:
        parent[rb]=ra

for i in range(len(files)):
    for j in range(i+1,len(files)):

        if hashes[i]-hashes[j]<=PHASH_THRESHOLD:
            union(i,j)

groups={}

for i in range(len(files)):
    root=find(i)
    groups.setdefault(root,[]).append(i)

groups=list(groups.values())

print("Similarity groups:",len(groups))

random.shuffle(groups)

targets={
    "train":0.70,
    "validation":0.15,
    "test":0.15
}

class_totals={
    c:sum(1 for x in files if x[0]==c)
    for c in CLASSES
}

target_counts={
    split:{
        c:round(class_totals[c]*ratio)
        for c in CLASSES
    }
    for split,ratio in targets.items()
}

for c in CLASSES:
    target_counts["train"][c]=class_totals[c]-target_counts["validation"][c]-target_counts["test"][c]

counts={
    split:{c:0 for c in CLASSES}
    for split in targets
}

assignments=[]

for group in groups:

    group_classes=[files[i][0] for i in group]

    scores={}

    for split in ["train","validation","test"]:

        score=0

        for c in CLASSES:

            group_count=group_classes.count(c)
            remaining=target_counts[split][c]-counts[split][c]

            if remaining>=group_count:
                score+=group_count*10
            else:
                score-=abs(remaining-group_count)*10

        scores[split]=score

    split=max(scores,key=scores.get)

    assignments.append((split,group))

    for i in group:
        counts[split][files[i][0]]+=1

for split,group in assignments:

    for i in group:

        class_name,filename,path=files[i]

        destination=os.path.join(
            OUTPUT,
            split,
            class_name,
            filename
        )

        shutil.copy2(path,destination)

print("\n==============================")
print("MULTICLASS SPLIT")
print("==============================")

for split in ["train","validation","test"]:

    total=sum(counts[split].values())

    print(f"\n{split.upper()}")

    for c in CLASSES:
        print(f"{c:12}: {counts[split][c]}")

    print("TOTAL       :",total)