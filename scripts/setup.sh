#!/bin/bash

echo "=========================="
echo " AI STACK SETUP START "
echo "=========================="

cd "$(dirname "$0")"
BASE_DIR="$(pwd)/.."

echo ">>> Step 1: Install Docker"
bash "$BASE_DIR/scripts/install_docker.sh"

echo ""
echo ">>> Step 2: Load env"
if [ -f "$BASE_DIR/.env" ]; then
    export $(grep -v '^#' "$BASE_DIR/.env" | xargs)
fi

echo ""
echo ">>> Step 3: Start Docker Stack"
cd "$BASE_DIR"
docker compose pull
docker compose up -d

echo ""
echo ">>> Waiting..."
sleep 6
docker compose ps

echo ""
echo "=========================="
echo " AI STACK READY (CPU MODE)"
echo "=========================="
echo "✔ Ollama API:    http://<server-ip>:11434"
echo "✔ Kong Proxy:    http://<server-ip>:8000"
echo "✔ Kong Admin:    http://<server-ip>:8001"
echo "✔ Prometheus:    http://<server-ip>:9090"
