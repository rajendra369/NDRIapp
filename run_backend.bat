@echo off
echo Starting Meteorological Backend Server...
cd c:\Users\raj10\Desktop\AntiG\app
python -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
pause
