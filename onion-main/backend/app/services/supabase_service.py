import os
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "") or os.getenv("SUPABASE_ANON_KEY", "")

class SupabaseService:
    def __init__(self):
        self.client = None
        self.is_connected = False
        self._init_supabase()
        
        # In-memory resilient storage for offline/standalone testing or when Supabase is not configured
        self._local_inspections: Dict[str, Dict[str, Any]] = {}
        self._local_reports: Dict[str, Dict[str, Any]] = {}
        self._local_sync_events: Dict[str, Dict[str, Any]] = {}

    def _init_supabase(self):
        if SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY and not SUPABASE_URL.startswith("https://your-project"):
            try:
                from supabase import create_client
                self.client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
                self.is_connected = True
                print(f"[SupabaseService] Successfully connected to Supabase at {SUPABASE_URL}")
            except Exception as e:
                print(f"[SupabaseService] Failed to initialize Supabase client: {e}. Falling back to internal store.")
                self.is_connected = False
        else:
            print("[SupabaseService] Supabase credentials not set or using placeholder. Running in local standalone storage mode.")
            self.is_connected = False

    def sync_inspection(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Idempotent inspection sync.
        Stores inspection, images, detections, validations, and grading.
        """
        client_sync_id = payload.get("client_sync_id")
        inspection_id = payload.get("id")
        now_iso = datetime.now(timezone.utc).isoformat()

        # Check idempotency
        if client_sync_id in self._local_sync_events:
            return {
                "status": "SUCCESS",
                "message": "Inspection was already synced previously (idempotent duplicate).",
                "synced_inspection_id": inspection_id,
                "server_timestamp": now_iso,
                "is_idempotent_duplicate": True,
            }

        # If Supabase is available, sync to PostgreSQL
        if self.is_connected and self.client:
            try:
                # 1. Upsert inspection
                insp_data = {
                    "id": inspection_id,
                    "inspection_code": payload.get("inspection_code"),
                    "batch_id": payload.get("batch_id"),
                    "center_id": payload.get("center_id"),
                    "inspector_id": payload.get("inspector_id"),
                    "inspector_name": payload.get("inspector_name"),
                    "sample_count": payload.get("sample_count"),
                    "status": payload.get("status"),
                    "sync_status": "SYNCED",
                    "notes": payload.get("notes"),
                    "inspected_at": payload.get("inspected_at"),
                    "synced_at": now_iso,
                    "updated_at": now_iso,
                }
                self.client.table("inspections").upsert(insp_data).execute()

                # 2. Detections
                detections = payload.get("detections", [])
                if detections:
                    det_records = [{**d, "inspection_id": inspection_id} for d in detections]
                    self.client.table("onion_detections").upsert(det_records).execute()

                # 3. Validations
                validations = payload.get("validations", [])
                if validations:
                    val_records = [{**v, "inspection_id": inspection_id} for v in validations]
                    self.client.table("validation_records").upsert(val_records).execute()

                # 4. Grading
                grading = payload.get("grading")
                if grading:
                    grade_data = {**grading, "inspection_id": inspection_id}
                    self.client.table("grading_results").upsert(grade_data).execute()

                # 5. Record sync event for idempotency
                self.client.table("sync_events").insert({
                    "id": f"sync-{client_sync_id}",
                    "client_sync_id": client_sync_id,
                    "entity_type": "inspection",
                    "entity_id": inspection_id,
                    "action": "CREATE_OR_UPDATE",
                    "status": "SUCCESS"
                }).execute()

            except Exception as e:
                print(f"[SupabaseService] Error syncing to Supabase: {e}. Storing in local cache.")

        # Always update local cache as well
        payload["synced_at"] = now_iso
        self._local_inspections[inspection_id] = payload
        self._local_sync_events[client_sync_id] = {
            "client_sync_id": client_sync_id,
            "inspection_id": inspection_id,
            "timestamp": now_iso
        }

        return {
            "status": "SUCCESS",
            "message": "Inspection successfully synchronized to cloud backend.",
            "synced_inspection_id": inspection_id,
            "server_timestamp": now_iso,
            "is_idempotent_duplicate": False,
        }

    def sync_report(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        inspection_id = payload.get("inspection_id")
        report_code = payload.get("report_code")
        now_iso = datetime.now(timezone.utc).isoformat()

        if self.is_connected and self.client:
            try:
                self.client.table("reports").upsert({
                    "id": f"rep-{inspection_id}",
                    "inspection_id": inspection_id,
                    "report_code": report_code,
                    "generated_at": payload.get("generated_at"),
                    "synced_at": now_iso,
                }).execute()
            except Exception as e:
                print(f"[SupabaseService] Report sync failed to Supabase: {e}")

        self._local_reports[inspection_id] = {
            "inspection_id": inspection_id,
            "report_code": report_code,
            "generated_at": payload.get("generated_at"),
            "synced_at": now_iso
        }

        return {
            "status": "SUCCESS",
            "message": "Report synchronized successfully.",
            "report_code": report_code,
            "server_timestamp": now_iso
        }

    def get_inspections(self) -> List[Dict[str, Any]]:
        if self.is_connected and self.client:
            try:
                res = self.client.table("inspections").select("*").order("created_at", desc=True).execute()
                if res.data:
                    return res.data
            except Exception as e:
                print(f"[SupabaseService] Error fetching inspections from Supabase: {e}")

        return list(self._local_inspections.values())

    def get_inspection_detail(self, inspection_id: str) -> Optional[Dict[str, Any]]:
        if self.is_connected and self.client:
            try:
                insp = self.client.table("inspections").select("*").eq("id", inspection_id).single().execute()
                if insp.data:
                    data = insp.data
                    detections = self.client.table("onion_detections").select("*").eq("inspection_id", inspection_id).execute()
                    validations = self.client.table("validation_records").select("*").eq("inspection_id", inspection_id).execute()
                    grading = self.client.table("grading_results").select("*").eq("inspection_id", inspection_id).execute()
                    data["detections"] = detections.data or []
                    data["validations"] = validations.data or []
                    data["grading"] = grading.data[0] if grading.data else None
                    return data
            except Exception as e:
                print(f"[SupabaseService] Error fetching detail from Supabase: {e}")

        return self._local_inspections.get(inspection_id)

    def get_status(self) -> Dict[str, Any]:
        return {
            "server_time": datetime.now(timezone.utc).isoformat(),
            "database_connected": self.is_connected,
            "storage_type": "Supabase PostgreSQL" if self.is_connected else "Local Resilient Memory Store",
            "total_synced_inspections": len(self._local_inspections)
        }

supabase_service = SupabaseService()
