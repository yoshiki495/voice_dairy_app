# Python 3.11 runtime as base image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV GOOGLE_CLOUD_PROJECT=voice-dairy-app-70a9d
ENV FIRESTORE_DATABASE=default

# Install system dependencies required for audio processing and ML libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    libsndfile1 \
    libsndfile1-dev \
    ffmpeg \
    cmake \
    pkg-config \
    libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .
COPY models/ ./models/

# Create a non-root user for security
RUN useradd --create-home --shell /bin/bash app
USER app

# Expose port
EXPOSE 8080

# Use gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "4", "--timeout", "300", "main:app"]