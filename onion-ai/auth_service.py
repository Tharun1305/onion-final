import os
import time
import secrets
import sqlite3
from typing import Optional, Dict, Any, List
import bcrypt
from dotenv import load_dotenv

# Load environment configuration (.env)
load_dotenv()

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "users.db")

# Default pre-computed bcrypt hashes for testing if .env has not overridden them
# Password for account 1: Admin@Onion2026
# Password for account 2: Inspector1@2026
# Password for account 3: Inspector2@2026
# Password for account 4: Inspector3@2026
# Password for account 5: Inspector4@2026
DEFAULT_ACCOUNTS = [
    {
        "id": "acc-1",
        "email": "admin@onion.ai",
        "username": "admin",
        "password_hash": "$2b$12$F./WVpgvQhfK9zswKeRHMOVfufTX4TKyzyI/OKNOmupNSVABGCqci",
        "name": "Administrator",
        "role": "Super Admin",
    },
    {
        "id": "acc-2",
        "email": "inspector1@onion.ai",
        "username": "inspector1",
        "password_hash": "$2b$12$440JoBE4liOk9SRVP.0DvOD12UklISe/KKiNNrZ7jCePMUsAx6bK6",
        "name": "Ramesh Shinde",
        "role": "Senior Quality Inspector",
    },
    {
        "id": "acc-3",
        "email": "inspector2@onion.ai",
        "username": "inspector2",
        "password_hash": "$2b$12$ap8B0Ls7WLL9BZJrRwtyaenVGFpJbyTDOz6YjJUvshRM5frrF9FjK",
        "name": "Sunita Patil",
        "role": "Quality Assessor",
    },
    {
        "id": "acc-4",
        "email": "inspector3@onion.ai",
        "username": "inspector3",
        "password_hash": "$2b$12$j2.2syDk6zY4v9g3awrv5.ikcFQCqf82RvVTCktX35RvOPvM0ePSi",
        "name": "Arun Kumar",
        "role": "Procurement Inspector",
    },
    {
        "id": "acc-5",
        "email": "inspector4@onion.ai",
        "username": "inspector4",
        "password_hash": "$2b$12$NKffwm8uyIlwaJ1esN86WOjkcSR3XICNiHaNSVw4SCrM7HFRplbzK",
        "name": "Vikram Deshmukh",
        "role": "Audit Assessor",
    },
]

class AuthService:
    """
    Static 5-Account Authentication Service.
    Enforces that ONLY the 5 predefined accounts can ever log in.
    No sign up, no OTP, no password reset, no plaintext passwords.
    """
    def __init__(self, db_path: str = DB_PATH):
        self.db_path = db_path
        self._init_db()
        self.accounts = self._load_accounts()

    def _get_connection(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            # Sessions table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS sessions (
                    token TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    identifier TEXT NOT NULL,
                    name TEXT NOT NULL,
                    role TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    expires_at REAL NOT NULL
                )
            """)
            # User-associated inspections table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS inspections (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    client_sync_id TEXT,
                    data_json TEXT NOT NULL,
                    created_at REAL NOT NULL
                )
            """)
            conn.commit()

    def _load_accounts(self) -> List[Dict[str, Any]]:
        """Load exactly 5 predefined accounts from environment or defaults."""
        accounts = []
        for i in range(1, 6):
            env_email = os.getenv(f"ACCOUNT_{i}_EMAIL") or os.getenv(f"ACCOUNT_{i}_IDENTIFIER")
            env_hash = os.getenv(f"ACCOUNT_{i}_PASSWORD_HASH")
            env_name = os.getenv(f"ACCOUNT_{i}_NAME")
            env_role = os.getenv(f"ACCOUNT_{i}_ROLE")

            default = DEFAULT_ACCOUNTS[i - 1]

            email = (env_email.strip().lower() if env_email else default["email"])
            username = email.split("@")[0].lower()
            pwd_hash = (env_hash.strip() if env_hash else default["password_hash"])
            name = (env_name.strip() if env_name else default["name"])
            role = (env_role.strip() if env_role else default["role"])

            accounts.append({
                "id": f"acc-{i}",
                "email": email,
                "username": username,
                "password_hash": pwd_hash,
                "name": name,
                "role": role,
            })
        return accounts

    def login(self, username_or_email: str, password: str) -> Dict[str, Any]:
        """
        Verify credentials against the 5 static accounts.
        Returns generic error if credentials do not match any account.
        """
        clean_input = username_or_email.strip().lower()
        if not clean_input or not password:
            raise ValueError("Invalid username or password")

        # Find matching account among exactly the 5 allowed accounts
        matched_account = None
        for acc in self.accounts:
            if clean_input == acc["email"] or clean_input == acc["username"]:
                matched_account = acc
                break

        if not matched_account:
            # Constant-time dummy check to prevent timing attack enumeration
            bcrypt.checkpw(password.encode("utf-8"), b"$2b$12$e80yq7Kj4U0LgH7u7R4U6OG1v0M6yW7dF1lO0U6w5yG0L8h7u7R4U")
            raise ValueError("Invalid username or password")

        # Verify password against bcrypt hash
        try:
            is_valid = bcrypt.checkpw(
                password.encode("utf-8"),
                matched_account["password_hash"].encode("utf-8")
            )
        except Exception:
            is_valid = False

        if not is_valid:
            raise ValueError("Invalid username or password")

        # Generate secure session token
        now = time.time()
        session_token = f"sess_{secrets.token_urlsafe(32)}"
        session_expiry = now + (30 * 86400) # 30 days session

        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO sessions (token, user_id, identifier, name, role, created_at, expires_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                session_token,
                matched_account["id"],
                matched_account["email"],
                matched_account["name"],
                matched_account["role"],
                now,
                session_expiry
            ))
            conn.commit()

        return {
            "status": "SUCCESS",
            "token": session_token,
            "user": {
                "id": matched_account["id"],
                "name": matched_account["name"],
                "email": matched_account["email"],
                "username": matched_account["username"],
                "role": matched_account["role"],
                "center_name": "APMC Onion Procurement Center",
                "district": "Nashik",
                "state": "Maharashtra"
            }
        }

    def validate_session(self, token: str) -> Optional[Dict[str, Any]]:
        """Validate an authentication token against active sessions."""
        if not token:
            return None
        now = time.time()
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT user_id, identifier, name, role FROM sessions
                WHERE token = ? AND expires_at > ?
            """, (token, now))
            row = cursor.fetchone()
            if row:
                return {
                    "id": row["user_id"],
                    "email": row["identifier"],
                    "username": row["identifier"].split("@")[0],
                    "name": row["name"],
                    "role": row["role"],
                    "center_name": "APMC Onion Procurement Center",
                    "district": "Nashik",
                    "state": "Maharashtra"
                }
        return None

    def logout(self, token: str):
        """Invalidate session token."""
        if not token:
            return
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM sessions WHERE token = ?", (token,))
            conn.commit()

    def sync_user_inspection(self, user_id: str, inspection_data: Dict[str, Any]) -> Dict[str, Any]:
        """Save inspection explicitly associated with the authenticated user."""
        insp_id = inspection_data.get("id") or f"insp-{secrets.token_hex(6)}"
        client_sync_id = inspection_data.get("client_sync_id") or insp_id
        import json

        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO inspections (id, user_id, client_sync_id, data_json, created_at)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    user_id = excluded.user_id,
                    data_json = excluded.data_json
            """, (insp_id, user_id, client_sync_id, json.dumps(inspection_data), time.time()))
            conn.commit()

        return {
            "status": "SUCCESS",
            "message": "Inspection synced for authenticated account.",
            "inspection_id": insp_id,
            "user_id": user_id
        }

    def get_user_inspections(self, user_id: str) -> List[Dict[str, Any]]:
        """Retrieve inspections belonging only to this authenticated user."""
        import json
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT data_json FROM inspections WHERE user_id = ? ORDER BY created_at DESC", (user_id,))
            rows = cursor.fetchall()
            return [json.loads(row["data_json"]) for row in rows]

auth_service = AuthService()
