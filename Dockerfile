# Multi-stage build: Frontend
FROM node:22-alpine AS frontend-build

WORKDIR /app/UI

COPY UI/package*.json ./

RUN npm install

COPY UI .

RUN npm run build

# Final stage: Backend + Frontend
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including Node.js for serving frontend
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY Server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY Server .

# Copy frontend build from builder stage
COPY --from=frontend-build /app/UI/dist ./public

# Create necessary directories
RUN mkdir -p uploads uploads/{assessments,submissions,smekit,resumes,proofs}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8000}/health || exit 1

EXPOSE 8000

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
