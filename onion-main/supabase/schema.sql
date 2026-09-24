-- ========================================================================
-- AI-POWERED ONION QUALITY ASSESSMENT & GRADING SYSTEM
-- Supabase / PostgreSQL Database Schema
-- ========================================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Procurement Centers
CREATE TABLE IF NOT EXISTS procurement_centers (
    id VARCHAR(64) PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    state VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Users / Inspectors
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    role VARCHAR(50) DEFAULT 'inspector',
    center_id VARCHAR(64) REFERENCES procurement_centers(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Inspections
CREATE TABLE IF NOT EXISTS inspections (
    id VARCHAR(64) PRIMARY KEY,
    inspection_code VARCHAR(64) NOT NULL UNIQUE,
    batch_id VARCHAR(64) NOT NULL,
    center_id VARCHAR(64) REFERENCES procurement_centers(id) ON DELETE SET NULL,
    inspector_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    inspector_name VARCHAR(255) NOT NULL,
    sample_count INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    sync_status VARCHAR(50) NOT NULL DEFAULT 'LOCAL_ONLY',
    notes TEXT,
    inspected_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    synced_at TIMESTAMP WITH TIME ZONE
);

-- 4. Inspection Sample Images
CREATE TABLE IF NOT EXISTS inspection_images (
    id VARCHAR(64) PRIMARY KEY,
    inspection_id VARCHAR(64) NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    sample_number INTEGER NOT NULL,
    image_url TEXT,
    local_path TEXT,
    blur_score REAL DEFAULT 0.0,
    quality_status VARCHAR(50) DEFAULT 'PASSED',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Onion Detections (AI Output)
CREATE TABLE IF NOT EXISTS onion_detections (
    id VARCHAR(64) PRIMARY KEY,
    inspection_id VARCHAR(64) NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    image_id VARCHAR(64),
    bbox_x REAL NOT NULL,
    bbox_y REAL NOT NULL,
    bbox_w REAL NOT NULL,
    bbox_h REAL NOT NULL,
    ai_class VARCHAR(50) NOT NULL,
    ai_confidence REAL NOT NULL,
    size_category VARCHAR(50) NOT NULL DEFAULT 'normal',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Validation Records (Human Verification Audit Trail)
CREATE TABLE IF NOT EXISTS validation_records (
    id VARCHAR(64) PRIMARY KEY,
    inspection_id VARCHAR(64) NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    detection_id VARCHAR(64) NOT NULL REFERENCES onion_detections(id) ON DELETE CASCADE,
    original_ai_class VARCHAR(50) NOT NULL,
    ai_confidence REAL NOT NULL,
    inspector_class VARCHAR(50) NOT NULL,
    correction_reason TEXT,
    final_class VARCHAR(50) NOT NULL,
    is_corrected BOOLEAN NOT NULL DEFAULT FALSE,
    validated_by VARCHAR(255),
    validated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Grading Results (Calculated via Grading Engine)
CREATE TABLE IF NOT EXISTS grading_results (
    id VARCHAR(64) PRIMARY KEY,
    inspection_id VARCHAR(64) NOT NULL UNIQUE REFERENCES inspections(id) ON DELETE CASCADE,
    total_sample INTEGER NOT NULL,
    grade_a_count INTEGER NOT NULL,
    grade_a_percentage REAL NOT NULL,
    urs_count INTEGER NOT NULL,
    urs_percentage REAL NOT NULL,
    other_defects_count INTEGER NOT NULL,
    other_defects_percentage REAL NOT NULL,
    final_grade VARCHAR(50) NOT NULL,
    rules_version VARCHAR(32) DEFAULT 'v1.0-demo',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Digital Quality Reports
CREATE TABLE IF NOT EXISTS reports (
    id VARCHAR(64) PRIMARY KEY,
    inspection_id VARCHAR(64) NOT NULL UNIQUE REFERENCES inspections(id) ON DELETE CASCADE,
    report_code VARCHAR(64) NOT NULL UNIQUE,
    pdf_url TEXT,
    local_pdf_path TEXT,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    synced_at TIMESTAMP WITH TIME ZONE
);

-- 9. Sync Events (Audit log for idempotency)
CREATE TABLE IF NOT EXISTS sync_events (
    id VARCHAR(64) PRIMARY KEY,
    client_sync_id VARCHAR(64) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(64) NOT NULL,
    action VARCHAR(50) NOT NULL,
    client_timestamp TIMESTAMP WITH TIME ZONE,
    server_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'SUCCESS'
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_inspections_center ON inspections(center_id);
CREATE INDEX IF NOT EXISTS idx_inspections_batch ON inspections(batch_id);
CREATE INDEX IF NOT EXISTS idx_inspections_code ON inspections(inspection_code);
CREATE INDEX IF NOT EXISTS idx_detections_inspection ON onion_detections(inspection_id);
CREATE INDEX IF NOT EXISTS idx_validations_inspection ON validation_records(inspection_id);
CREATE INDEX IF NOT EXISTS idx_sync_events_client ON sync_events(client_sync_id);

-- Sample Seed Data
INSERT INTO procurement_centers (id, code, name, location, state)
VALUES 
    ('center-nashik-01', 'PC-NSK-01', 'Lasalgaon Onion APMC Center', 'Lasalgaon, Nashik', 'Maharashtra'),
    ('center-pune-02', 'PC-PUN-02', 'Pune Gultekdi Market Yard', 'Gultekdi, Pune', 'Maharashtra'),
    ('center-indore-03', 'PC-IND-03', 'Devi Ahilya Bai Holkar APMC', 'Indore', 'Madhya Pradesh')
ON CONFLICT (id) DO NOTHING;

INSERT INTO users (id, username, full_name, email, role, center_id)
VALUES 
    ('insp-001', 'inspector.shinde', 'Ramesh Shinde', 'r.shinde@agri-procure.gov.in', 'senior_inspector', 'center-nashik-01'),
    ('insp-002', 'inspector.patil', 'Sunita Patil', 's.patil@agri-procure.gov.in', 'quality_assessor', 'center-nashik-01')
ON CONFLICT (id) DO NOTHING;
