#!/bin/bash

# Cloud Run Voice Emotion Analysis API Deployment Script
# 音声感情分析API Cloud Runデプロイスクリプト

set -e  # Exit on any error

# Configuration
PROJECT_ID="voice-dairy-app-70a9d"
SERVICE_NAME="voice-emotion-analysis"
REGION="asia-northeast1"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "🚀 Starting deployment of Voice Emotion Analysis API to Cloud Run"

# Check if required files exist
if [ ! -f "main.py" ]; then
    echo "❌ Error: main.py not found"
    exit 1
fi

if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Dockerfile not found"
    exit 1
fi

if [ ! -d "models" ]; then
    echo "❌ Error: models directory not found"
    exit 1
fi

# Check if model files exist
MODEL_FILES=("best_emotion_classifier_pipeline.pkl" "best_emotion_regressor_pipeline.pkl" "label_encoder.pkl")
for file in "${MODEL_FILES[@]}"; do
    if [ ! -f "models/$file" ]; then
        echo "❌ Error: Model file models/$file not found"
        exit 1
    fi
done

echo "✅ All required files found"

# Authenticate with Google Cloud (if needed)
echo "🔐 Checking Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "Please authenticate with Google Cloud:"
    gcloud auth login
fi

# Set project
echo "🎯 Setting Google Cloud project to ${PROJECT_ID}..."
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build and submit the Docker image
echo "🏗️  Building Docker image..."
gcloud builds submit --tag ${IMAGE_NAME} --timeout=30m

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
    --image ${IMAGE_NAME} \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --memory 2Gi \
    --cpu 1 \
    --timeout 300 \
    --concurrency 10 \
    --max-instances 10 \
    --set-env-vars GOOGLE_CLOUD_PROJECT=${PROJECT_ID},FIRESTORE_DATABASE=default

# Get the service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --format='value(status.url)')

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Service URL: ${SERVICE_URL}"
echo ""
echo "📊 Test endpoints:"
echo "  Health Check: ${SERVICE_URL}/health"
echo "  Test Function: ${SERVICE_URL}/test"
echo ""
echo "🔗 API Endpoints:"
echo "  GET  ${SERVICE_URL}/health"
echo "  POST ${SERVICE_URL}/test"
echo "  POST ${SERVICE_URL}/get-upload-url"
echo "  POST ${SERVICE_URL}/analyze-emotion"
echo "  POST ${SERVICE_URL}/get-mood-data"
echo ""
echo "📝 Note: All POST endpoints (except /test) require Firebase Authentication"
echo "   Include 'Authorization: Bearer <firebase-id-token>' in request headers"
echo ""
echo "🎉 Deployment complete! Your Voice Emotion Analysis API is now running on Cloud Run."