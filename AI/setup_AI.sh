#!/bin/bash

echo "================================"
echo "  AI SERVER SETUP START"
echo "================================"

cd "$(dirname "$0")"

# --------------------------
# Step 1: Install Docker
# --------------------------
echo ">>> Step 1: Check Docker installation"
if ! command -v docker >/dev/null 2>&1; then
    echo ">>> Installing Docker..."
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
# Step 2: Start Docker Stack
# --------------------------
echo ""
echo ">>> Step 2: Start AI Server containers"
docker compose pull
docker compose up -d

echo ""
echo ">>> Waiting for Ollama to be ready..."
sleep 10

# --------------------------
# Step 3: Pull AI Model
# --------------------------
echo ""
echo ">>> Step 3: Pull AI model qwen2.5-coder:1.5b"

OLLAMA_CONTAINER=$(docker ps --filter "name=ollama" --format "{{.ID}}")

if [ -z "$OLLAMA_CONTAINER" ]; then
    echo "!!! Error: Ollama container not found!"
    exit 1
fi

# Check if model exists
docker exec $OLLAMA_CONTAINER ollama list | grep -q "qwen2.5-coder:1.5b"

if [ $? -ne 0 ]; then
    echo ">>> Pulling model qwen2.5-coder:1.5b..."
    docker exec $OLLAMA_CONTAINER ollama pull qwen2.5-coder:1.5b
    echo ">>> Model pulled successfully!"
else
    echo ">>> Model qwen2.5-coder:1.5b already available"
fi

# --------------------------
# Done
# --------------------------
echo ""
echo "================================"
echo "  AI SERVER READY"
echo "================================"

AI_SERVER_IP=$(curl -s ifconfig.me || echo "localhost")

echo ""
echo "✔ Ollama API:     http://$AI_SERVER_IP:11434"
echo "✔ Ollama Metrics: http://$AI_SERVER_IP:9178/metrics"
echo ""
echo "📝 Save this IP for Gateway Server configuration: $AI_SERVER_IP"
echo ""
