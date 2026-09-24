import sys
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_full_backend_sync():
    print("--- 1. Testing Health & Root ---")
    res = client.get("/health")
    assert res.status_code == 200, f"Health failed: {res.text}"
    print(f"Health check: {res.json()}")

    print("\n--- 2. Testing Inspector Login ---")
    login_res = client.post("/auth/login", json={
        "username": "inspector.shinde",
        "password": "procure@2026"
    })
    assert login_res.status_code == 200, f"Login failed: {login_res.text}"
    user_data = login_res.json()
    print(f"Logged in user: {user_data['full_name']} (Role: {user_data['role']})")

    print("\n--- 3. Testing Inspection Sync (Initial) ---")
    sync_payload = {
        "client_sync_id": "client-sync-uuid-001",
        "id": "insp-uuid-2026-001",
        "inspection_code": "INS-2026-000124",
        "batch_id": "ON-2026-0042",
        "center_id": "center-nashik-01",
        "inspector_id": "insp-001",
        "inspector_name": "Ramesh Shinde",
        "sample_count": 42,
        "status": "COMPLETED",
        "notes": "Morning procurement lot, Lasalgaon APMC",
        "inspected_at": "2026-09-12T10:00:00Z",
        "created_at": "2026-09-12T10:00:00Z",
        "updated_at": "2026-09-12T10:15:00Z",
        "images": [
            {
                "id": "img-001",
                "sample_number": 1,
                "local_path": "/storage/samples/sample_1.jpg",
                "blur_score": 0.88,
                "quality_status": "PASSED",
                "created_at": "2026-09-12T10:05:00Z"
            }
        ],
        "detections": [
            {
                "id": "det-001",
                "image_id": "img-001",
                "bbox_x": 0.12,
                "bbox_y": 0.15,
                "bbox_w": 0.20,
                "bbox_h": 0.20,
                "ai_class": "healthy",
                "ai_confidence": 0.94,
                "size_category": "normal",
                "created_at": "2026-09-12T10:06:00Z"
            },
            {
                "id": "det-002",
                "image_id": "img-001",
                "bbox_x": 0.40,
                "bbox_y": 0.15,
                "bbox_w": 0.22,
                "bbox_h": 0.21,
                "ai_class": "damaged",
                "ai_confidence": 0.88,
                "size_category": "normal",
                "created_at": "2026-09-12T10:06:00Z"
            }
        ],
        "validations": [
            {
                "id": "val-001",
                "detection_id": "det-001",
                "original_ai_class": "healthy",
                "ai_confidence": 0.94,
                "inspector_class": "healthy",
                "correction_reason": None,
                "final_class": "healthy",
                "is_corrected": False,
                "validated_by": "Ramesh Shinde",
                "validated_at": "2026-09-12T10:10:00Z"
            },
            {
                "id": "val-002",
                "detection_id": "det-002",
                "original_ai_class": "damaged",
                "ai_confidence": 0.88,
                "inspector_class": "healthy",
                "correction_reason": "Surface skin dried flake; bulb intact and healthy",
                "final_class": "healthy",
                "is_corrected": True,
                "validated_by": "Ramesh Shinde",
                "validated_at": "2026-09-12T10:11:00Z"
            }
        ],
        "grading": {
            "id": "grd-001",
            "total_sample": 42,
            "grade_a_count": 36,
            "grade_a_percentage": 85.7,
            "urs_count": 4,
            "urs_percentage": 9.5,
            "other_defects_count": 2,
            "other_defects_percentage": 4.8,
            "final_grade": "Grade A (Procurement Standard)",
            "rules_version": "v1.0-demo",
            "created_at": "2026-09-12T10:12:00Z"
        }
    }

    sync_res = client.post("/inspections/sync", json=sync_payload)
    assert sync_res.status_code == 200, f"Sync failed: {sync_res.text}"
    sync_data = sync_res.json()
    print(f"Sync response: {sync_data}")
    assert sync_data["status"] == "SUCCESS"
    assert sync_data["is_idempotent_duplicate"] is False

    print("\n--- 4. Testing Idempotency on Duplicate Sync ---")
    dup_res = client.post("/inspections/sync", json=sync_payload)
    assert dup_res.status_code == 200
    dup_data = dup_res.json()
    print(f"Duplicate sync response: {dup_data}")
    assert dup_data["is_idempotent_duplicate"] is True, "Expected duplicate flag to be True"

    print("\n--- 5. Testing Inspection Retrieval ---")
    detail_res = client.get("/inspections/insp-uuid-2026-001")
    assert detail_res.status_code == 200
    detail = detail_res.json()
    print(f"Retrieved: Code={detail['inspection_code']}, Batch={detail['batch_id']}, Grade={detail['grading']['final_grade']}")
    print(f"Detections count: {len(detail['detections'])}, Validations count: {len(detail['validations'])}")

    print("\n--- 6. Testing Digital Report Metadata Sync ---")
    rep_res = client.post("/reports/sync", json={
        "inspection_id": "insp-uuid-2026-001",
        "report_code": "INS-2026-000124",
        "generated_at": "2026-09-12T10:14:00Z"
    })
    assert rep_res.status_code == 200
    print(f"Report sync: {rep_res.json()}")

    print("\n--- 7. Testing Sync Status ---")
    status_res = client.get("/sync/status")
    assert status_res.status_code == 200
    print(f"Sync status: {status_res.json()}")

    print("\n>>> ALL BACKEND TESTS PASSED SUCCESSFULLY! <<<")

if __name__ == "__main__":
    test_full_backend_sync()
