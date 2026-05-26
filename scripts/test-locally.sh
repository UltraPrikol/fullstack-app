#!/bin/bash
# Скрипт для локального тестирования CI/CD пайплайна

set -e

echo "🔧 Testing CI/CD pipeline locally..."

# Тестирование фронтенда
echo "📦 Testing frontend..."
cd frontend
npm ci
npm run lint
npm run build
cd ..

# Тестирование бэкенда
echo "🐍 Testing backend..."
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install pytest pytest-cov
pytest --cov=. --cov-report=term
deactivate
cd ..

# Тестирование Docker сборки
echo "🐳 Testing Docker build..."
docker build -t book-api:test ./backend
docker run --rm book-api:test python -c "import main; print('✅ Import successful')"

echo "✅ All local tests passed!"