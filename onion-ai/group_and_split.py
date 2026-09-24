import os
import shutil
import random
from PIL import Image
import imagehash

SOURCE="dataset/raw"
OUTPUT="dataset"
SEED=42
PHASH_THRESHOLD=4

random.seed(SEED)

classes=["healthy","unhealthy"]
images=[]

for class_name in classes:
    folder=os.path.join(SOURCE,class_name)

    for file in os.listdir(folder):
        path=os.path.join(folder,file)

        try:
            with Image.open(path) as img:
                img=img.convert("RGB")
                h=imagehash.phash(img)

                images.append({
                    "path":path,
                    "class":class_name,
                    "hash":h
                })
        except:
            pass

print("Images loaded:",len(images))

parent=list(range(len(images)))

def find(x):
    while parent[x]!=x:
        parent[x]=parent[parent[x]]
        x=parent[x]
    return x

def union(a,b):
    a=find(a)
    b=find(b)

    if a!=b:
        parent[b]=a

print("Building similarity groups...")

for i in range(len(images)):
    for j in range(i+1,len(images)):
        if images[i]["hash"]-images[j]["hash"]<=PHASH_THRESHOLD:
            union(i,j)

groups={}

for i in range(len(images)):
    root=find(i)
    groups.setdefault(root,[]).append(i)

groups=list(groups.values())

print("Similarity groups:",len(groups))

group_info=[]

for group in groups:
    healthy=sum(images[i]["class"]=="healthy" for i in group)
    unhealthy=sum(images[i]["class"]=="unhealthy" for i in group)

    group_info.append({
        "group":group,
        "size":len(group),
        "healthy":healthy,
        "unhealthy":unhealthy
    })

random.shuffle(group_info)

total_healthy=sum(g["healthy"] for g in group_info)
total_unhealthy=sum(g["unhealthy"] for g in group_info)
total=total_healthy+total_unhealthy

print("Healthy:",total_healthy)
print("Unhealthy:",total_unhealthy)
print("Total:",total)

target_sizes={
    "train":round(total*0.70),
    "validation":round(total*0.15),
    "test":total-round(total*0.70)-round(total*0.15)
}

target_healthy={
    "train":round(total_healthy*0.70),
    "validation":round(total_healthy*0.15),
    "test":total_healthy-round(total_healthy*0.70)-round(total_healthy*0.15)
}

target_unhealthy={
    "train":round(total_unhealthy*0.70),
    "validation":round(total_unhealthy*0.15),
    "test":total_unhealthy-round(total_unhealthy*0.70)-round(total_unhealthy*0.15)
}

print("\nTARGETS")

for split in ["train","validation","test"]:
    print(
        split.upper(),
        "total:",target_sizes[split],
        "healthy:",target_healthy[split],
        "unhealthy:",target_unhealthy[split]
    )

splits={
    "train":[],
    "validation":[],
    "test":[]
}

counts={
    "train":{"healthy":0,"unhealthy":0,"total":0},
    "validation":{"healthy":0,"unhealthy":0,"total":0},
    "test":{"healthy":0,"unhealthy":0,"total":0}
}

def split_score(group,split):
    h=group["healthy"]
    u=group["unhealthy"]
    s=group["size"]

    new_h=counts[split]["healthy"]+h
    new_u=counts[split]["unhealthy"]+u
    new_total=counts[split]["total"]+s

    target_h=target_healthy[split]
    target_u=target_unhealthy[split]
    target_total=target_sizes[split]

    class_score=(
        abs(new_h-target_h)/(target_h+1)
        +
        abs(new_u-target_u)/(target_u+1)
    )

    size_score=abs(new_total-target_total)/(target_total+1)

    overflow=max(0,new_total-target_total)/(target_total+1)

    return class_score*3+size_score+overflow*10

# Large groups first
group_info.sort(key=lambda x:x["size"],reverse=True)

for group in group_info:

    possible=[]

    for split in ["train","validation","test"]:

        current=counts[split]["total"]
        target=target_sizes[split]

        # Don't allow a split to exceed target by more than
        # the size of the current group unless unavoidable.
        overflow=current+group["size"]-target

        if overflow<=group["size"]:
            possible.append(
                (split_score(group,split),split)
            )

    if not possible:
        possible=[
            (split_score(group,split),split)
            for split in ["train","validation","test"]
        ]

    possible.sort(key=lambda x:x[0])

    split=possible[0][1]

    splits[split].append(group)

    counts[split]["healthy"]+=group["healthy"]
    counts[split]["unhealthy"]+=group["unhealthy"]
    counts[split]["total"]+=group["size"]

# Improve assignment using whole groups
# by moving groups between splits when it reduces total error.

def total_error():
    error=0

    for split in ["train","validation","test"]:
        error+=abs(
            counts[split]["healthy"]-target_healthy[split]
        )

        error+=abs(
            counts[split]["unhealthy"]-target_unhealthy[split]
        )

        error+=abs(
            counts[split]["total"]-target_sizes[split]
        )

    return error

for _ in range(10000):

    improved=False
    current_error=total_error()

    for source in ["train","validation","test"]:

        for group in splits[source]:

            for destination in ["train","validation","test"]:

                if source==destination:
                    continue

                splits[source].remove(group)
                splits[destination].append(group)

                for key in ["healthy","unhealthy","total"]:
                    if key=="total":
                        value=group["size"]
                    else:
                        value=group[key]

                    counts[source][key]-=value
                    counts[destination][key]+=value

                new_error=total_error()

                if new_error<current_error:
                    improved=True
                    current_error=new_error
                    break

                for key in ["healthy","unhealthy","total"]:
                    if key=="total":
                        value=group["size"]
                    else:
                        value=group[key]

                    counts[source][key]+=value
                    counts[destination][key]-=value

                splits[destination].remove(group)
                splits[source].append(group)

            if improved:
                break

        if improved:
            break

    if not improved:
        break

# Clear old split
for split in ["train","validation","test"]:
    for class_name in classes:

        folder=os.path.join(
            OUTPUT,
            split,
            class_name
        )

        if os.path.exists(folder):
            shutil.rmtree(folder)

        os.makedirs(folder,exist_ok=True)

# Copy files
for split in ["train","validation","test"]:

    for group in splits[split]:

        for index in group["group"]:

            src=images[index]["path"]
            class_name=images[index]["class"]

            dst=os.path.join(
                OUTPUT,
                split,
                class_name,
                os.path.basename(src)
            )

            shutil.copy2(src,dst)

print("\nFINAL SPLIT")

for split in ["train","validation","test"]:

    h=counts[split]["healthy"]
    u=counts[split]["unhealthy"]
    t=counts[split]["total"]

    print(f"\n{split.upper()}")
    print("healthy:",h)
    print("unhealthy:",u)
    print("Total:",t)

print("\nTotal assigned:",sum(
    counts[s]["total"]
    for s in ["train","validation","test"]
))

print("\nGROUPED STRATIFIED SPLIT CREATED")