#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "================================"
echo " DEPLOY AI SERVER"
echo "================================"

cd "$ROOT_DIR/IaC/AI"
./deploy_ai.sh

echo ""
read -p "Enter AI Server IP: " AI_SERVER_IP

if [ -z "$AI_SERVER_IP" ]; then
  echo "AI Server IP is required"
  exit 1
fi

echo ""
echo "Waiting for AI Server ($AI_SERVER_IP)..."

until curl -sf "http://$AI_SERVER_IP:9178/metrics" > /dev/null; do
  sleep 5
done

echo "AI Server is ready"

echo ""
echo "================================"
echo " DEPLOY GATEWAY SERVER"
echo "================================"

cd "$ROOT_DIR/IaC/Gateway"

terraform init -input=false
terraform apply -auto-approve \
  -var="ai_server_ip=$AI_SERVER_IP"

echo ""
echo "================================"
echo " DEPLOY ALL DONE"
echo "================================"
