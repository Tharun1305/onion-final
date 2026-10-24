@echo off
title Onion AI FastAPI Server
color 0A
echo ============================================================
echo   ONION AI - FastAPI Server Startup
echo ============================================================
echo.
cd /d "%~dp0"
if exist "venv\Scripts\activate.bat" (
    echo [*] Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo [!] No venv found. Using system Python.
)
echo [*] Starting FastAPI server on http://127.0.0.1:8000
echo [*] Press Ctrl+C to stop the server.
echo.
python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload
echo.
echo [!] Server stopped.
pause
