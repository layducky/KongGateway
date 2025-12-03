#!/bin/bash

echo "=========================="
echo " AI STACK SETUP START "
echo "=========================="

cd "$(dirname "$0")"


# --------------------------------------------------
# Step 0: Ask user for AI server private IP
# --------------------------------------------------
echo ""
echo ">>> Enter AI Server IP (Ollama private IP): "
read -p "AI_IP = " AI_IP

# Validate IPv4
if [[ ! $AI_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "!!! Error: Invalid IP format."
    exit 1
fi

export AI_IP
echo ">>> Using AI Server IP: $AI_IP"
echo ""

# --------------------------
# Step 1: Install Docker
# --------------------------
echo ">>> Step 1: Install Docker"
if ! command -v docker >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER
    echo ">>> Docker installed. Logout & login again recommended."
else
    echo ">>> Docker already installed"
fi

# --------------------------
# Step 2: Load env
# --------------------------
echo ""
echo ">>> Step 2: Load env"
if [ -f "/.env" ]; then
    export $(grep -v '^#' "/.env" | xargs)
fi

# --------------------------
# Step 3: Start Docker Stack
# --------------------------
echo ""
echo ">>> Step 3: Start Docker Stack"
docker compose pull
docker compose up -d

echo ""
echo ">>> Waiting for containers..."
sleep 6
docker compose ps
# --------------------------
# Step 4: Bootstrap Kong and Wait
# --------------------------
echo ""
echo ">>> Step 4: Bootstrap Kong"
docker compose stop kong
docker compose run --rm kong kong migrations bootstrap
docker compose up -d kong
echo ">>> Kong bootstrapped!"

# --- ADDED: Wait for Kong Admin API to be available ---
MAX_RETRIES=10
RETRY_COUNT=0
echo ">>> Waiting for Kong Admin (8001) to be ready..."
until curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/status | grep 200 > /dev/null || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
  sleep 3
  RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "!!! Error: Kong Admin API failed to start after $MAX_RETRIES attempts. Aborting configuration."
  exit 1
fi
echo ">>> Kong Admin API is ready."
# -----------------------------------------------------

# --------------------------
# Step 5: Configure Kong routes for Ollama
# --------------------------
echo ""
echo ">>> Step 5: Configure Kong routes for Ollama"

# 1. Tạo Service
curl -s -X POST http://localhost:8001/services/ \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"ollama\",
    \"url\": \"http://$AI_IP:11434\"
  }"

# 2. Tạo Route
curl -s -X POST http://localhost:8001/services/ollama/routes \
  -H "Content-Type: application/json" \
  -d '{
    "paths": ["/ollama"],
    "strip_path": true
  }'

echo ">>> Kong routes for Ollama configured successfully!"

# --------------------------
# Done
# --------------------------
echo ""
echo "=========================="
echo " AI STACK READY "
echo "=========================="
ip=$(curl -s ifconfig.me || echo "localhost")

echo "✔ Kong Proxy:    http://$ip:8000"
echo "✔ Kong Admin:    http://$ip:8001"
echo "✔ Prometheus:    http://$ip:9090"
