#!/bin/bash
# Скрипт для ручного деплоя (запасной вариант)

set -e

echo "🚀 Manual deployment started..."

# Деплой фронтенда
echo "📱 Deploying frontend to Vercel..."
cd frontend
vercel --prod
cd ..

# Сборка и публикация бэкенда
echo "📦 Building and pushing backend..."
cd backend
docker build -t book-api:latest .
REGISTRY_ID=$(yc container registry get book-api-registry --format json | jq -r '.id')
docker tag book-api:latest cr.yandex/$REGISTRY_ID/book-api:latest
docker push cr.yandex/$REGISTRY_ID/book-api:latest
cd ..

# Деплой в Cloud Run
echo "☁️ Deploying to Cloud Run..."
yc serverless container revision deploy \
  --container-name book-api-container \
  --image cr.yandex/$REGISTRY_ID/book-api:latest \
  --cores 1 \
  --memory 512MB

echo "✅ Manual deployment completed!"