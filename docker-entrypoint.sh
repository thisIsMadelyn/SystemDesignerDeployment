#!/bin/sh
set -e

echo "Starting FastAPI..."
cd /app/backend
uvicorn main:app --host 127.0.0.1 --port 8000 &

echo "Starting nginx..."
nginx -g "daemon off;"
