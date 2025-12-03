#!/bin/bash

echo "=========================="
echo " AI STACK SETUP START "
echo "=========================="

cd "$(dirname "$0")"
BASE_DIR="$(pwd)/.."

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
# Step 2: Start Docker Stack
# --------------------------
echo ""
echo ">>> Step 2: Start Docker Stack"
cd "$BASE_DIR"
docker compose pull
docker compose up -d

echo ""
echo ">>> Waiting for containers..."
sleep 6
docker compose ps

# --------------------------
# Step 3: Pull model if not exists
# --------------------------
echo ""
echo ">>> Step 3: Ensure model qwen2.5-coder:1.5b is available"

OLLAMA_CONTAINER=$(docker ps --filter "ancestor=ollama/ollama:latest" --format "{{.ID}}")

if [ -z "$OLLAMA_CONTAINER" ]; then
    echo ">>> Ollama container not found!"
else
    docker exec -it $OLLAMA_CONTAINER ollama list | grep -q "qwen2.5-coder:1.5b"
    if [ $? -ne 0 ]; then
        echo ">>> Pulling model qwen2.5-coder:1.5b..."
        docker exec -it $OLLAMA_CONTAINER ollama pull qwen2.5-coder:1.5b
        echo ">>> Model pulled!"
    else
        echo ">>> Model qwen2.5-coder:1.5b already available"
    fi
fi

# --------------------------
# Done
# --------------------------
echo ""
echo "=========================="
echo " AI STACK READY"
echo "=========================="
ip=$(curl -s ifconfig.me || echo "localhost")

echo "✔ Ollama API:    http://$ip:11434"
