# AI-Powered Onion Quality Assessment & Grading System (Offline-First Mobile MVP)

> **Quality assessment and grading of onions are often subjective and vary across procurement centers, resulting in disputes and inconsistencies.**

This repository contains a **real, functional offline-first mobile MVP** designed for **onion procurement and quality inspectors**. It provides an on-device AI-assisted inspection workflow, human-in-the-loop verification, configurable rule-based grading, offline PDF report generation, local SQLite persistence, and idempotent cloud synchronization with a FastAPI backend and Supabase PostgreSQL database.

---

## 1. System Architecture

```text
                 FLUTTER MOBILE APP
                         │
          ┌──────────────┴──────────────┐
          │                             │
     CAMERA / GALLERY              SQLITE DATABASE
          │                             │
          ▼                             │
   IMAGE QUALITY CHECK                  │
          │                             │
          ▼                             │
  ON-DEVICE AI MODEL                   │
          │                             │
          ▼                             │
  DEFECT / SIZE ANALYSIS                │
          │                             │
          ▼                             │
   LOCAL GRADING ENGINE                 │
          │                             │
          ▼                             │
 INSPECTOR VALIDATION                   │
          │                             │
          ▼                             │
   LOCAL PDF REPORT                     │
          │                             │
          └──────────┬──────────────────┘
                     │
                 SYNC QUEUE
                     │
              Internet available
                     │
                     ▼
                  FASTAPI
                     │
                     ▼
             SUPABASE POSTGRES
                     │
                     ├── Storage
                     └── Auth
```

---

## 2. The Complete Inspection Loop

1. **Inspector Login**: Offline session-aware authentication (`inspector.shinde`, `inspector.patil`).
2. **Dashboard**: Live connectivity indicator (`ONLINE` / `OFFLINE` with interactive toggle for testing), today's inspections, pending sync count, and recent inspection feed.
3. **Create Inspection**: Auto-generates reference ID (e.g. `INS-2026-000124`), records Batch ID (`ON-2026-0042`), APMC Procurement Center, and Inspector name.
4. **Sample Capture**: Camera or gallery input supporting multiple sample trays (Sample 1, Sample 2, ...) with built-in instant sample generators for testing.
5. **Image Quality Check**: Validates resolution, checks for blur or extreme lighting conditions with "Retake" or "Use Anyway" overrides.
6. **On-Device AI Analysis**: Step-by-step progress tracking (`Checking image...`, `Detecting onions...`, `Analyzing defects...`, `Evaluating quality...`, `Calculating grade...`).
7. **AI Result Screen**: Bounding box visual overlays with colored defect tags (`Healthy`, `Damaged`, `Rotten`, `Sprouted`, `Undersized`), confidence scores, and size estimations.
8. **Human-in-the-Loop Validation**: Inspector reviews each detected onion, accepts or changes classifications, and records audited correction reasons. Original AI predictions are never overwritten.
9. **Configurable Grading Engine**: Computes Grade A %, URS (Under-Recovery Sample) %, and Defect % using configurable rules.
10. **Digital Quality Report**: 100% offline generation of official PDF quality reports saved to local device storage with audit trails and signature verification.
11. **Inspection History**: Local SQLite storage allows reviewing past inspections completely offline.
12. **Idempotent Cloud Sync**: Background `SyncQueue` with automatic network transition detection, retries, and duplicate prevention synced to FastAPI and Supabase.

---

## 3. Project Structure

```text
d:\SIH2026\onion/
│
├── onion_app/                      # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/          # Enums, colors, APMC centers
│   │   │   ├── network/            # Real & simulated connectivity service
│   │   │   └── theme/              # Procurement palette & Material 3
│   │   ├── data/
│   │   │   ├── local/              # SQLite DatabaseHelper (Android & Desktop FFI)
│   │   │   └── repositories/       # Local inspection repository
│   │   ├── models/                 # Inspection, Detection, Validation, Grading, Sync
│   │   ├── features/
│   │   │   ├── auth/               # Inspector session & login screen
│   │   │   ├── dashboard/          # Dashboard metrics & quick actions
│   │   │   ├── inspection/         # Create form, camera capture & quality dialog
│   │   │   ├── ai_analysis/        # AI engine abstraction, demo engine & UI overlay
│   │   │   ├── validation/         # Human review & override screen
│   │   │   ├── grading/            # Configurable grading engine & final summary
│   │   │   ├── reports/            # Offline PDF generator & viewer
│   │   │   ├── history/            # History listing & complete audit drilldown
│   │   │   └── sync/               # Resilient background sync queue
│   │   └── main.dart
│   ├── test/                       # Unit tests for grading engine & AI engine
│   └── pubspec.yaml
│
├── backend/                        # FastAPI Synchronization Backend
│   ├── app/
│   │   ├── main.py                 # FastAPI endpoints
│   │   ├── schemas.py              # Pydantic schemas
│   │   └── services/               # Supabase service with local fallback
│   ├── test_sync.py                # Automated backend test suite
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
│
└── supabase/                       # Supabase PostgreSQL DDL
    └── schema.sql                  # Complete schema with indexes & seed data
```

---

## 4. Setup & Running Instructions

### A. Mobile Application (Flutter)

#### 1. Prerequisites
- Flutter SDK (>= 3.13.0)
- Android Studio / Android SDK (for Android build) or Windows Desktop build tools

#### 2. Run the App
```bash
cd onion_app
flutter pub get
```

To run on **Windows Desktop** (instant local desktop execution):
```bash
flutter run -d windows
```

To run on an **Android Device or Emulator**:
```bash
flutter run -d android
```

To run unit tests:
```bash
flutter test
```

---

### B. Cloud Backend (FastAPI & Supabase)

#### 1. Install Python Dependencies
```bash
cd backend
pip install -r requirements.txt
```

#### 2. Configure Environment (Optional for live Supabase)
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Provide your Supabase credentials:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
PORT=8000
HOST=0.0.0.0
```
*(Note: If Supabase credentials are not provided, the backend operates in a resilient in-memory standalone mode so you can test cloud sync without external dependencies).*

#### 3. Run the Backend Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- API Documentation (Swagger): `http://localhost:8000/docs`
- Health check: `http://localhost:8000/health`

#### 4. Run Automated Backend Tests
```bash
python test_sync.py
```

---

### C. Supabase Database Schema

Run the SQL migration in `supabase/schema.sql` inside the Supabase SQL Editor:
- Creates `users`, `procurement_centers`, `inspections`, `inspection_images`, `onion_detections`, `validation_records`, `grading_results`, `reports`, and `sync_events`.
- Sets up foreign keys with `ON DELETE CASCADE` and indexes on `batch_id`, `inspection_code`, `center_id`, and `client_sync_id`.
- Pre-seeds Lasalgaon, Pune, and Indore APMC centers with inspector credentials.

---

## 5. On-Device AI Architecture & Model Integration

### AI Abstraction Interface
The app uses a strict clean architecture abstraction:

```dart
abstract class OnionInferenceEngine {
  String get engineName;
  bool get isSimulation;
  Future<List<OnionDetection>> analyze({
    required String inspectionId,
    required String imagePath,
    int sampleNumber = 1,
  });
}
```

Two implementations are provided:
1. `DemoInferenceEngine`: Generates realistic multi-onion sample grid bounding boxes, defect labels (`Healthy`, `Damaged`, `Rotten`, `Sprouted`, `Undersized`), and confidence scores (82%–98%) with a simulated 450ms CPU inference delay.
2. `RealOnDeviceInferenceEngine`: Production skeleton wired for a quantized Int8 TFLite/ONNX model (`assets/models/onion_detector_quantized.tflite`).

### How to Replace Demo Inference with a Real Trained Model:
1. Train a lightweight object detection model (e.g. YOLOv8n, MobileNetV4) on annotated onion datasets.
2. Quantize the model to Int8 TFLite (`tflite_convert --optimizations DEFAULT`).
3. Place the `.tflite` model in `onion_app/assets/models/onion_detector_quantized.tflite` and register the asset in `pubspec.yaml`.
4. In `lib/features/ai_analysis/presentation/ai_analysis_screen.dart`, instantiate `RealOnDeviceInferenceEngine` instead of `DemoInferenceEngine`.

---

## 6. Configurable Grading Engine

The system strictly follows the principle:

$$\text{AI Observation} \longrightarrow \text{Inspector Validated Observation} \longrightarrow \text{Grading Rules Engine} \longrightarrow \text{Final Grade}$$

The AI model does **not** directly output "Grade A = 82%". Instead, `GradingEngine` applies explicit configurable thresholds:

```dart
class GradingThresholdConfig {
  final double minGradeAHealthyPercentage; // 70.0%
  final double maxGradeARottenPercentage;   // 5.0%
  final double maxGradeADamagedPercentage; // 15.0%
  final double minUrsHealthyPercentage;     // 50.0%
  final double maxUrsRottenPercentage;      // 8.0%
  final String rulesVersion;                // 'v1.0-demo-thresholds'
}
```

This allows official government procurement standards to replace the demo thresholds without modifying any UI or inference code.

---

## 7. Offline-First Data & Human Audit Guarantee

- **Zero Internet Requirement for Inspection**: All steps (sample capture, image quality check, AI inference, inspector review, grading calculation, PDF generation) execute locally on the device using SQLite.
- **Auditable Human-in-the-Loop**: When an inspector overrides an AI prediction, both records are stored side-by-side:
  - `original_ai_class` & `ai_confidence` (never overwritten)
  - `inspector_class`, `correction_reason`, and `final_class`
  - `is_corrected = true`
- **Idempotent Synchronization**: Every sync payload includes a unique `client_sync_id` and `inspection_id`. If network drops or retries occur, the backend detects duplicate submissions and prevents duplicate records.
