#!/bin/bash

echo "=========================="
echo " AI STACK SETUP START "
echo "=========================="

cd "$(dirname "$0")"
BASE_DIR="$(pwd)/.."

echo ">>> Step 1: Install Docker"
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
echo ">>> Docker installed. Logout & login again recommended."

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
echo ">>> Step 4: Bootstrap Kong"
docker compose stop kong
docker compose run --rm kong kong migrations bootstrap
docker compose up -d kong
echo ">>> Kong bootstrapped!"

echo ""
echo "=========================="
echo " AI STACK READY (CPU MODE)"
echo "=========================="
echo "✔ Ollama API:    http://<server-ip>:11434"
echo "✔ Kong Proxy:    http://<server-ip>:8000"
echo "✔ Kong Admin:    http://<server-ip>:8001"
echo "✔ Prometheus:    http://<server-ip>:9090"
