#!/bin/bash

echo "================================"
echo "  GATEWAY SERVER SETUP START"
echo "================================"

cd "$(dirname "$0")"

# --------------------------
# Step 0: Get AI Server IP
# --------------------------
echo ">>> Please enter AI Server IP address:"
read -p "AI_SERVER_IP (e.g., 192.168.1.100): " AI_SERVER_IP

if [ -z "$AI_SERVER_IP" ]; then
    echo "!!! Error: AI Server IP is required!"
    exit 1
fi

echo ">>> Using AI Server: $AI_SERVER_IP"

# --------------------------
# Step 1: Install Docker
# --------------------------
echo ""
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
# Step 2: Create Prometheus config
# --------------------------
echo ""
echo ">>> Step 2: Create Prometheus configuration"

mkdir -p prometheus

cat > prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Kong metrics
  - job_name: 'kong'
    static_configs:
      - targets: ['kong:8001']
    metrics_path: '/metrics'

  # Ollama metrics from AI Server
  - job_name: 'ollama'
    static_configs:
      - targets: ['$AI_SERVER_IP:9178']
    metrics_path: '/metrics'
EOF

echo ">>> Prometheus config created with AI Server: $AI_SERVER_IP:9178"

# --------------------------
# Step 3: Start Docker Stack
# --------------------------
echo ""
echo ">>> Step 3: Start Gateway Server containers"
docker compose pull
docker compose up -d

echo ""
echo ">>> Waiting for containers to be ready..."
sleep 6

# --------------------------
# Step 4: Bootstrap Kong
# --------------------------
echo ""
echo ">>> Step 4: Bootstrap Kong database"
docker compose stop kong
docker compose run --rm kong kong migrations bootstrap
docker compose up -d kong

# Wait for Kong to be ready
MAX_RETRIES=15
RETRY_COUNT=0

echo ">>> Waiting for Kong Admin API to be ready..."
until curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/status | grep 200 > /dev/null || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
    sleep 3
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "    Retry $RETRY_COUNT/$MAX_RETRIES..."
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "!!! Error: Kong Admin API failed to start. Aborting."
    exit 1
fi

echo ">>> Kong Admin API is ready!"

# --------------------------
# Step 5: Configure Kong routes
# --------------------------
echo ""
echo ">>> Step 5: Configure Kong to route to AI Server"

# Create Service pointing to AI Server
curl -s -X POST http://localhost:8001/services/ \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"ollama\", \"url\": \"http://$AI_SERVER_IP:11434\"}"

# Create Route
curl -s -X POST http://localhost:8001/services/ollama/routes \
  -H "Content-Type: application/json" \
  -d '{"paths": ["/ollama"], "strip_path": true}'

echo ""
echo ">>> Kong configured to forward requests to AI Server!"

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
echo "🔗 AI Server:   http://$AI_SERVER_IP:11434"
echo ""
echo "Test connection:"
echo "  curl http://$GATEWAY_IP:8000/ollama/api/version"
echo ""