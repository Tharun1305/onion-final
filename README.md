
# 🧅 AI-Powered Onion Disease Detection & Quality Grading System

> **Detect with AI. Verify with expertise. Grade with evidence.**

An AI-powered computer vision system designed to assist farmers, inspectors, and procurement centers in detecting visible onion defects and generating a standardized quality assessment from onion images.

The system combines **YOLO-based object detection** with a **CNN-based classification model (EfficientNetV2-S)** to identify onion defects, estimate prediction confidence, and support inspector-verified quality grading.

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Problem Statement](#-problem-statement)
- [Solution](#-solution)
- [Objectives](#-objectives)
- [Key Features](#-key-features)
- [Unique Selling Proposition](#-unique-selling-proposition)
- [How the System Works](#-how-the-system-works)
- [System Architecture](#-system-architecture)
- [AI Methodology](#-ai-methodology)
- [Disease and Quality Classes](#-disease-and-quality-classes)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Dataset](#-dataset)
- [Model Training](#-model-training)
- [Installation](#-installation)
- [Usage](#-usage)
- [Sample Output](#-sample-output)
- [Quality Grading](#-quality-grading)
- [Stakeholder Impact](#-stakeholder-impact)
- [Advantages](#-advantages)
- [Limitations](#-limitations)
- [Future Enhancements](#-future-enhancements)
- [Performance Evaluation](#-performance-evaluation)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgements](#-acknowledgements)

---

# 🌱 Overview

Onion quality assessment is often performed through visual inspection. Manual inspection can vary between inspectors, can be time-consuming at higher volumes, and may make it difficult to maintain a consistent digital record of the assessment.

This project introduces an **AI-assisted onion inspection pipeline** that analyzes onion images to identify visible quality defects.

The system is designed around a **Human-in-the-Loop** approach:

**Image → AI Detection → Defect Classification → Confidence Score → Inspector Verification → Final Grade → Digital Record**

The purpose is not to replace inspectors, but to provide them with consistent AI-based decision support.

---

# ❗ Problem Statement

Onion quality can be affected by several visible defects such as:

- Rot
- Mold
- Physical damage
- Sprouting
- Surface defects
- Other visible quality deterioration

Traditional inspection processes may face challenges such as:

- Subjective visual assessment
- Variation between inspectors
- Repetitive manual screening
- Difficulty handling large volumes
- Limited traceability
- Lack of structured quality data
- Delayed identification of defective onions

A scalable solution needs to combine **automation, transparency, human verification, and digital traceability**.

---

# 💡 Solution

Our solution is an **AI-powered onion disease detection and quality grading system**.

It uses computer vision to:

1. Detect individual onions in an image.
2. Localize each onion using bounding boxes.
3. Crop detected onions for detailed analysis.
4. Classify the onion into predefined defect/quality categories.
5. Calculate class probabilities and confidence scores.
6. Generate an AI-assisted quality assessment.
7. Allow an inspector to verify the AI result.
8. Store the final assessment as structured quality data.

---

# 🎯 Objectives

The primary objectives of the project are:

- Detect visible onion defects automatically.
- Improve consistency in quality assessment.
- Reduce repetitive manual screening.
- Provide explainable AI-assisted decisions.
- Support inspector verification.
- Create traceable digital inspection records.
- Enable scalable deployment at procurement and quality centers.
- Build a foundation for future agricultural quality analytics.

---

# 🚀 Key Features

## 1. AI-Based Onion Detection

A YOLO-based object detection model identifies individual onions in an image.

The detector provides:

- Bounding box coordinates
- Object confidence
- Number of detected onions

---

## 2. Multi-Class Defect Classification

Each detected onion is passed to a CNN-based classification model.

The proposed classifier uses **EfficientNetV2-S** for image classification.

The model predicts the most likely disease or quality category.

---

## 3. Confidence-Aware Prediction

Instead of returning only a label, the system produces probability/confidence information.

Example:

```text
Healthy      : 0.08
Damaged      : 0.05
Black Rot    : 0.72
Mold         : 0.10
Soft Rot     : 0.03
Sprouted     : 0.02

This allows the inspector to understand how strongly the model supports a prediction.

4. Inspector Verification

The system follows a Human-in-the-Loop workflow:

AI Detects
     ↓
AI Classifies
     ↓
Confidence Score
     ↓
Inspector Reviews
     ↓
Final Grade

The final quality decision is therefore not treated as an unexplained AI output.

5. Digital Quality Record

Each inspection can be converted into a structured record containing information such as:

Inspection ID
Image ID
Detected Onion Count
Defect Category
Confidence Score
AI Grade
Inspector Verification
Final Grade
Timestamp

This enables traceability and future analytics.

6. Offline-First Design

The project is designed with field deployment in mind.

An offline-first version can perform inference locally, reducing dependency on continuous internet connectivity in locations where network availability may be limited.

⭐ Unique Selling Proposition
1. 🤖 AI-Powered Multi-Defect Detection

Detects and classifies multiple visible onion quality defects rather than limiting the system to a simple healthy/damaged prediction.

2. 👨‍🔬 AI-Assisted, Inspector-Verified Grading

AI recommends → Inspector verifies → Final grade is recorded

This combines machine-assisted screening with human accountability.

3. 📊 Explainable & Traceable Assessment

The system connects:

Detected Defect → Confidence → Grade → Digital Quality Record

This creates evidence-based and traceable quality assessment.

🔄 How the System Works
Step 1 — Image Capture

An onion image is captured using:

Smartphone camera
Inspection camera
USB camera
Uploaded image
Step 2 — Preprocessing

The image is prepared for AI inference.

Typical preprocessing includes:

Image resizing
Normalization
Tensor conversion
Optional augmentation during training
Step 3 — YOLO Detection

YOLO detects individual onions.

Example:

Input Image
    ↓
YOLO Object Detector
    ↓
Onion Bounding Boxes
Step 4 — Onion Cropping

Detected onion regions are extracted from the original image.

Each crop is processed independently.

Step 5 — CNN Classification

Each onion crop is classified using the trained CNN model.

Proposed architecture:

EfficientNetV2-S

Step 6 — Confidence Calculation

The classifier generates class probabilities.

The highest probability class is selected as the AI prediction.

Step 7 — Quality Grading

The disease/defect classification is mapped to an AI-assisted quality grade according to the project's grading rules.

Step 8 — Inspector Verification

The inspector reviews:

Detected defect
Confidence score
Image evidence
Suggested grade

The inspector confirms or modifies the final result.

Step 9 — Digital Record

The final inspection can be stored in a database or exported as a quality report.

🏗️ System Architecture
                  ┌─────────────────────┐
                  │   Onion Image Input │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │   Preprocessing     │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ YOLO Object Detector│
                  └──────────┬──────────┘
                             │
                    Detected Onion Boxes
                             │
                             ▼
                  ┌─────────────────────┐
                  │  Crop Extraction    │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ EfficientNetV2-S    │
                  │ Classifier          │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ Defect + Confidence │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ Grading Engine      │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ Inspector           │
                  │ Verification        │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ Final Grade +       │
                  │ Digital Record      │
                  └─────────────────────┘
🧠 AI Methodology

The system uses a two-stage computer vision pipeline.

Stage 1 — Object Detection
Model

YOLO

Purpose:

Detect individual onions
Locate onions in complex images
Generate bounding boxes
Support batch-level inspection
Stage 2 — Image Classification
Model

EfficientNetV2-S

Purpose:

Analyze individual onion crops
Extract visual features
Classify visible quality defects
Produce class probabilities
Overall Pipeline
Image
  ↓
YOLO
  ↓
Onion Detection
  ↓
Crop
  ↓
EfficientNetV2-S
  ↓
Disease / Quality Class
  ↓
Confidence
  ↓
Grading Engine
  ↓
Inspector Verification
  ↓
Final Result
🧅 Disease and Quality Classes

The proposed six-class classification setup contains:

Class	Description
Healthy	Onion with no visible target defect
Damaged	Visible physical or mechanical damage
Black Rot	Visible dark/black rot-related symptoms
Mold	Visible fungal/mold-like growth
Soft Rot	Visible signs associated with soft deterioration
Sprouted	Onion showing visible sprouting

Note: The class definitions and labels should be aligned with the final annotated dataset and domain-expert validation used by the project.

🛠️ Technology Stack
Artificial Intelligence
Python
PyTorch / TensorFlow
YOLO
EfficientNetV2-S
OpenCV
NumPy
Pandas
Backend

Possible implementation:

FastAPI / Flask
REST API
Python inference service
Frontend

Possible implementation:

React
HTML
CSS
JavaScript
Database

Possible options:

MySQL
PostgreSQL
Firebase
SQLite for lightweight/local deployment
Deployment

Possible deployment targets:

Local PC
Edge device
Android application
Web application
Cloud server
📁 Project Structure
onion-disease-detection/
│
├── dataset/
│   ├── images/
│   ├── labels/
│   ├── train/
│   ├── val/
│   └── test/
│
├── detection/
│   ├── train.py
│   ├── predict.py
│   └── weights/
│
├── classification/
│   ├── train.py
│   ├── predict.py
│   └── models/
│
├── preprocessing/
│   └── image_preprocessing.py
│
├── grading/
│   └── grading_engine.py
│
├── api/
│   └── app.py
│
├── frontend/
│   └── ...
│
├── notebooks/
│   ├── data_analysis.ipynb
│   └── model_evaluation.ipynb
│
├── outputs/
│   ├── predictions/
│   └── reports/
│
├── requirements.txt
├── README.md
└── LICENSE
📊 Dataset

The model requires a labeled onion image dataset.

The dataset should contain images representing the target classes under realistic conditions.

Recommended dataset diversity

Images should include variation in:

Onion size
Onion color
Lighting
Background
Camera quality
Viewing angle
Disease severity
Storage conditions
Multiple onions per image
Dataset Annotation

For object detection, each onion should be annotated using bounding boxes.

For example:

class_id x_center y_center width height

normalized according to the selected YOLO annotation format.

For classification, each cropped onion image should be associated with a class label.

🧪 Model Training
Object Detection Training

Example workflow:

python detection/train.py

Typical training process:

Dataset
   ↓
Annotation Validation
   ↓
Train / Validation / Test Split
   ↓
YOLO Training
   ↓
Validation
   ↓
Best Model Selection
Classification Training

Example:

python classification/train.py

Typical workflow:

Cropped Onion Images
        ↓
Preprocessing
        ↓
Data Augmentation
        ↓
EfficientNetV2-S
        ↓
Training
        ↓
Validation
        ↓
Test Evaluation
📦 Installation
1. Clone the Repository
git clone https://github.com/<your-username>/onion-disease-detection.git
cd onion-disease-detection
2. Create a Virtual Environment
Windows
python -m venv venv
venv\Scripts\activate
Linux / macOS
python3 -m venv venv
source venv/bin/activate
3. Install Dependencies
pip install -r requirements.txt
4. Verify Installation
python --version
pip --version
▶️ Usage
Image Prediction

Example:

python detection/predict.py --source sample.jpg

Then classify the detected onion crops:

python classification/predict.py --source crops/
API Mode

Start the backend:

python api/app.py

The application can then receive an onion image and return structured prediction data.

Example response:

{
  "detected_onions": 4,
  "predictions": [
    {
      "class": "Healthy",
      "confidence": 0.91
    },
    {
      "class": "Black Rot",
      "confidence": 0.72
    }
  ]
}
📋 Sample Output

Example AI-assisted inspection:

----------------------------------
      ONION QUALITY REPORT
----------------------------------

Detected Onions : 4

Onion 1
Disease   : Healthy
Confidence: 91%

Onion 2
Disease   : Black Rot
Confidence: 72%

Onion 3
Disease   : Damaged
Confidence: 84%

Onion 4
Disease   : Sprouted
Confidence: 88%

----------------------------------
Inspector Verification : Required
Final Grade             : Recorded
----------------------------------
📈 Quality Grading

The grading module maps model results to project-defined quality categories.

A grading rule may consider:

Type of detected defect
Severity
Number of affected onions
Defect proportion
Confidence threshold
Inspector verification

Example conceptual workflow:

Detection
   ↓
Defect Classification
   ↓
Severity / Defect Analysis
   ↓
Grade Recommendation
   ↓
Inspector Verification
   ↓
Final Grade

The exact grade thresholds should be configured according to the project's target quality standard and validated with domain experts.

👥 Core Benefits & Stakeholder Impact
👨‍🌾 Farmers & Suppliers
Fairer Grading → Fewer Disputes
Objective image-based assessment
Transparent defect evidence
Consistent quality evaluation
Digital inspection records
🔎 Inspectors
AI Speed + Human Accountability
Faster visual screening
Automated defect localization
Confidence-aware predictions
Inspector-controlled final decision
🏢 Procurement / Quality Centers
One Standard → Many Centers
Standardized inspection workflow
Scalable high-volume screening
Digital traceability
Structured quality data for analytics
💎 Why This Project Is Different

Most agricultural computer vision systems focus only on detecting a disease.

This project extends the workflow from:

IMAGE
  ↓
DETECTION
  ↓
CLASSIFICATION
  ↓
CONFIDENCE
  ↓
GRADING
  ↓
HUMAN VERIFICATION
  ↓
TRACEABLE RECORD

This turns a computer vision model into a complete inspection decision-support system.

✅ Advantages
Automated visual defect screening
Multi-class disease/quality recognition
Object detection for multiple onions
Confidence-based predictions
Human-in-the-loop validation
Standardized inspection workflow
Digital quality traceability
Potential for offline/edge deployment
Suitable for future large-scale quality analytics
⚠️ Limitations

The system has several practical limitations:

Prediction quality depends on dataset quality and diversity.
Camera angle and lighting can affect detection.
Some diseases can have visually similar symptoms.
Internal onion defects may not be visible externally.
Model performance may vary across onion varieties and growing/storage conditions.
AI output should be validated before being used for official procurement decisions.
🔮 Future Enhancements
1. Mobile Application

Develop an Android application that allows inspectors or field users to capture an onion image directly through a smartphone.

2. Edge AI

Deploy the trained model on edge devices for local inference in low-connectivity environments.

3. Severity Estimation

Move beyond classification and estimate the severity and affected surface area of defects.

4. Batch-Level Quality Analysis

Analyze an entire batch and generate:

Healthy percentage
Defect percentage
Class distribution
Recommended quality grade
Batch quality summary
5. Historical Analytics

Maintain historical inspection data to identify:

Recurring defect patterns
Storage-related deterioration
Supplier quality trends
Location-wise quality patterns
6. Multilingual Interface

Support regional languages to improve usability for local inspectors and agricultural stakeholders.

7. Continuous Model Improvement

New verified inspection samples can be added to the dataset for periodic retraining and model improvement.

📊 Performance Evaluation

The system should be evaluated separately for detection and classification.

Object Detection Metrics

Recommended metrics:

Precision
Recall
mAP@50
mAP@50:95
Inference time
Classification Metrics

Recommended metrics:

Accuracy
Precision
Recall
F1-Score
Confusion Matrix
Per-class performance
Real-World Evaluation

The final system should also be evaluated using realistic field conditions:

Different lighting
Different camera devices
Multiple onions in one image
Different varieties
Different defect severities
Different storage conditions

Report only measured results from the actual trained model. Do not use placeholder accuracy values in the final project report.

🚀 Deployment

The system can be deployed in multiple environments.

Local Application
Camera
   ↓
Local AI Model
   ↓
Prediction
   ↓
Inspector
Web Application
Browser
   ↓
Backend API
   ↓
AI Inference Server
   ↓
Prediction + Grade
Edge / Offline Application
Camera
   ↓
Edge Device
   ↓
Local AI Inference
   ↓
Inspector Verification
   ↓
Local Storage
   ↓
Sync when Internet is Available
🔐 Data & Privacy Considerations

The application should follow responsible data-handling practices.

Recommended practices:

Store only required inspection information.
Protect uploaded images and inspection records.
Use authentication for administrative dashboards.
Avoid exposing private farmer/supplier information.
Control access to quality records.
Maintain backups for important inspection data.
🧪 Example End-to-End Scenario

A procurement center receives a batch of onions.

Step 1

An inspector captures an image of the onions.

Step 2

YOLO identifies individual onions.

Step 3

Each onion crop is passed to EfficientNetV2-S.

Step 4

The model predicts the likely defect category and confidence.

Step 5

The grading engine generates an AI-assisted grade.

Step 6

The inspector reviews the evidence and confirms the result.

Step 7

The final assessment is stored digitally.

Result
Manual Visual Inspection
          ↓
AI-Assisted Screening
          ↓
Consistent Evidence
          ↓
Inspector Verification
          ↓
Traceable Quality Record
🌍 Expected Impact

The project is designed to support a transition from:

Traditional Model

Manual → Subjective → Slow → Difficult to Trace

to:

AI-Assisted Model

Automated Screening → Evidence-Based → Faster → Standardized → Traceable

The broader goal is to create a practical computer vision system that can support agricultural quality assessment while keeping humans responsible for final verification.

🏁 Project Vision

Build an intelligent, transparent and scalable quality inspection ecosystem for onions—connecting AI, inspectors, farmers and procurement centers through evidence-based quality assessment.

👨‍💻 Team

Project: AI-Powered Onion Disease Detection & Quality Grading System

Domain: Artificial Intelligence / Computer Vision / Agriculture

Primary Technologies: YOLO, EfficientNetV2-S, Python, OpenCV

🤝 Contributing

Contributions are welcome.

To contribute:

git clone https://github.com/<your-username>/onion-disease-detection.git
cd onion-disease-detection

Create a new branch:

git checkout -b feature/your-feature

Commit your changes:

git add .
git commit -m "Add new feature"

Push the branch:

git push origin feature/your-feature

Then create a Pull Request.

📄 License

This project is released under the license specified in the LICENSE file.

If a license has not yet been selected, choose an appropriate open-source license before publishing the repository.

🙏 Acknowledgements

We acknowledge the contribution of open-source computer vision and deep learning frameworks used in this project, including:

YOLO
EfficientNetV2
PyTorch / TensorFlow
OpenCV
NumPy
Pandas

We also acknowledge the importance of domain expertise and agricultural validation when developing AI-assisted quality assessment systems.

⭐ Final Message
AI doesn't replace the inspector.
AI gives the inspector better evidence.

Detect → Classify → Explain → Verify → Grade → Record



> **AI-powered onion disease detection and quality grading using YOLO + EfficientNetV2-S, with confidence-aware predictions, inspector verification, and digital quality traceability.**

> `Computer Vision | YOLO | EfficientNetV2-S | Onion Disease Detection | AI-Assisted Quality Grading | Agriculture`
