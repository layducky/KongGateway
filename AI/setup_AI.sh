#!/bin/bash
set -e

echo "================================"
echo "  AI SERVER SETUP START"
echo "================================"

cd "$(dirname "$0")"

# --------------------------
# Install Docker (if needed)
# --------------------------
echo ">>> Checking Docker"
if ! command -v docker >/dev/null 2>&1; then
    echo ">>> Installing Docker..."

    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER

    echo ">>> Docker installed"
else
    echo ">>> Docker already installed"
fi

# --------------------------
# Start containers
# --------------------------
echo ""
echo ">>> Starting AI containers"
docker compose pull
docker compose up -d

echo ">>> Waiting for Ollama..."
sleep 10

# --------------------------
# Pull AI model (if missing)
# --------------------------
MODEL="qwen2.5-coder:1.5b"
OLLAMA_CONTAINER=$(docker ps --filter "ancestor=ollama/ollama:latest" --format "{{.ID}}")

if [ -z "$OLLAMA_CONTAINER" ]; then
    echo "!!! Ollama container not found"
    exit 1
fi

if ! docker exec "$OLLAMA_CONTAINER" ollama list | grep -q "$MODEL"; then
    echo ">>> Pulling model $MODEL"
    docker exec "$OLLAMA_CONTAINER" ollama pull "$MODEL"
else
    echo ">>> Model $MODEL already exists"
fi

# --------------------------
# Done
# --------------------------
AI_SERVER_IP=$(curl -s ifconfig.me || echo "localhost")

echo ""
echo "================================"
echo "  AI SERVER READY"
echo "================================"
echo "✔ Ollama API:     http://$AI_SERVER_IP:11434"
echo "✔ Ollama Metrics: http://$AI_SERVER_IP:9178/metrics"
echo "📝 Save this IP:  $AI_SERVER_IP"
echo ""
