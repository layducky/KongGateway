#!/bin/bash

echo "================================"
echo "  GATEWAY SERVER SETUP START"
echo "================================"

cd "$(dirname "$0")"

# --------------------------
# Get AI Server IP from env
# --------------------------
if [ -z "$AI_SERVER_IP" ]; then
    read -p "Enter AI_SERVER_IP (e.g., 18.142.254.163): " AI_SERVER_IP
    if [ -z "$AI_SERVER_IP" ]; then
        echo "!!! Error: AI_SERVER_IP is required!"
        exit 1
    fi
fi

echo ">>> Using AI Server: $AI_SERVER_IP"

# --------------------------
# Install Docker
# --------------------------
echo ""
if ! command -v docker >/dev/null 2>&1; then
    echo ">>> Installing Docker..."
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker ubuntu
    echo ">>> Docker installed. Logout & login recommended."
else
    echo ">>> Docker already installed"
fi

# --------------------------
# Update Prometheus config
# --------------------------
echo ""
echo ">>> Updating prometheus.yml with AI Server IP..."
sed -i "s/__AI_SERVER_IP__/$AI_SERVER_IP/g" prometheus/prometheus.yml
echo ">>> Prometheus configured: $AI_SERVER_IP:9178"

# --------------------------
# Start Docker Stack
# --------------------------
echo ""
echo ">>> Starting containers..."
sudo docker compose pull
sudo docker compose up -d
sleep 6

# --------------------------
# Bootstrap Kong
# --------------------------
echo ""
echo ">>> Bootstrapping Kong..."
docker compose stop kong
docker compose run --rm kong kong migrations bootstrap
docker compose up -d kong

# Wait for Kong with better feedback
MAX_RETRIES=30
RETRY_COUNT=0
echo ">>> Waiting for Kong Admin API..."
until curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/status 2>/dev/null | grep 200 > /dev/null; do
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "!!! Error: Kong failed to start after 90s"
        echo ">>> Check logs: docker compose logs kong"
        exit 1
    fi
    sleep 3
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "    Attempt $RETRY_COUNT/$MAX_RETRIES..."
done

echo ">>> Kong is ready!"

# --------------------------
# Configure Kong routes
# --------------------------
echo ""
echo ">>> Configuring Kong routes..."
AI_SERVER_URL="http://$AI_SERVER_IP:9178"
SERVICE_NAME="ollama"

SERVICE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/services/$SERVICE_NAME)

if [ "$SERVICE_STATUS" -eq 200 ]; then
    echo "    Service '$SERVICE_NAME' existed. Updating URL (PATCH) to $AI_SERVER_URL..."
    curl -s -X PATCH http://localhost:8001/services/ollama \
      -H "Content-Type: application/json" \
      -d "{\"url\": \"$AI_SERVER_URL\"}" > /dev/null
else
    echo "    Service '$SERVICE_NAME' did not exist. Creating new (POST) with URL $AI_SERVER_URL..."
    curl -s -X POST http://localhost:8001/services/ \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"ollama\", \"url\": \"$AI_SERVER_URL\"}" > /dev/null
fi

curl -s -X POST http://localhost:8001/services/ollama/routes \
  -H "Content-Type: application/json" \
  -d '{"paths": ["/ollama"], "strip_path": true}' > /dev/null

echo ">>> Kong configured!"

# --------------------------
# Done
# --------------------------
echo ""
echo "================================"
echo "  GATEWAY SERVER READY"
echo "================================"
GATEWAY_IP=$(curl -s ifconfig.me || echo "localhost")
echo ""
echo "✔ Kong Proxy:  http://$GATEWAY_IP:8000"
echo "✔ Kong Admin:  http://$GATEWAY_IP:8001"
echo "✔ Prometheus:  http://$GATEWAY_IP:9090"
echo "✔ Grafana:     http://$GATEWAY_IP:3000"
echo ""
echo "AI Server:   http://$AI_SERVER_IP:9178"
echo ""
echo "Test: curl http://$GATEWAY_IP:8000/ollama/api/version"
echo ""