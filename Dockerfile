FROM python:3.11-slim

# Install system dependencies for WeasyPrint (PDF generation) and other tools
RUN apt-get update && apt-get install -y \
    libcairo2 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libffi-dev \
    shared-mime-info \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download the required spaCy model for NLP
RUN python -m spacy download en_core_web_md

# Copy the rest of the application code
COPY . .

# Expose port for the backend
EXPOSE 8000

# Start the FastAPI backend
# Cloud providers like Render pass the port via $PORT variable.
CMD ["sh", "-c", "uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
