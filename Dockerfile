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

# Optimize for memory (crucial for 512MB free tier hosting)
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV OPENBLAS_NUM_THREADS=1
ENV PYTHONUNBUFFERED=1

# Copy requirements and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download the smaller spaCy model to save RAM
RUN python -m spacy download en_core_web_sm

# Pre-cache the embedding model during build time so runtime doesn't download or spike memory
RUN python -c "from fastembed import TextEmbedding; list(TextEmbedding('sentence-transformers/all-MiniLM-L6-v2').embed(['warmup']))"

# Copy the rest of the application code
COPY . .

# Expose standard port for the backend
EXPOSE 8000

# Start the FastAPI backend
# Cloud platforms like Render pass the assigned port in $PORT
CMD ["sh", "-c", "uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
