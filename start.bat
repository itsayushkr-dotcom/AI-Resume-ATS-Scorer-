@echo off
echo Starting Backend (FastAPI)...
start cmd /k "python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload"

echo Starting Frontend (Streamlit)...
start cmd /k "streamlit run frontend/streamlit_app.py"

echo Both services started!
