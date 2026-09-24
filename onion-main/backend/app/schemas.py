from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

class LoginRequest(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: str
    username: str
    full_name: str
    role: str
    center_id: Optional[str] = None
    token: str

class InspectionImageSync(BaseModel):
    id: str
    sample_number: int
    local_path: Optional[str] = None
    image_base64: Optional[str] = None
    blur_score: float = 0.0
    quality_status: str = "PASSED"
    created_at: str

class OnionDetectionSync(BaseModel):
    id: str
    image_id: Optional[str] = None
    bbox_x: float
    bbox_y: float
    bbox_w: float
    bbox_h: float
    ai_class: str
    ai_confidence: float
    size_category: str = "normal"
    created_at: str

class ValidationRecordSync(BaseModel):
    id: str
    detection_id: str
    original_ai_class: str
    ai_confidence: float
    inspector_class: str
    correction_reason: Optional[str] = None
    final_class: str
    is_corrected: bool = False
    validated_by: Optional[str] = None
    validated_at: str

class GradingResultSync(BaseModel):
    id: str
    total_sample: int
    grade_a_count: int
    grade_a_percentage: float
    urs_count: int
    urs_percentage: float
    other_defects_count: int
    other_defects_percentage: float
    final_grade: str
    rules_version: str = "v1.0-demo"
    created_at: str

class InspectionSyncRequest(BaseModel):
    client_sync_id: str
    id: str
    inspection_code: str
    batch_id: str
    center_id: Optional[str] = None
    inspector_id: Optional[str] = None
    inspector_name: str
    sample_count: int
    status: str
    notes: Optional[str] = None
    inspected_at: str
    created_at: str
    updated_at: str
    images: List[InspectionImageSync] = []
    detections: List[OnionDetectionSync] = []
    validations: List[ValidationRecordSync] = []
    grading: Optional[GradingResultSync] = None

class SyncResponse(BaseModel):
    status: str
    message: str
    synced_inspection_id: str
    server_timestamp: str
    is_idempotent_duplicate: bool = False

class ReportSyncRequest(BaseModel):
    inspection_id: str
    report_code: str
    pdf_base64: Optional[str] = None
    generated_at: str

class SyncStatusResponse(BaseModel):
    server_time: str
    database_connected: bool
    storage_type: str
    total_synced_inspections: int
