#!/bin/bash
set -e

echo "================================"
echo "  DESTROY GATEWAY & AI SERVER"
echo "================================"

# Lấy thư mục hiện tại của script
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --------------------------
# Destroy Gateway
# --------------------------
echo ""
echo ">>> Destroying Gateway..."
cd "$ROOT_DIR/IaC/Gateway"
terraform destroy -auto-approve
echo ">>> Gateway destroyed!"

# --------------------------
# Destroy AI Server
# --------------------------
AI_DESTROY_SCRIPT="$ROOT_DIR/IaC/AI/destroy_ai.sh"

if [ -f "$AI_DESTROY_SCRIPT" ]; then
    echo ""
    echo ">>> Destroying AI Server..."
    bash "$AI_DESTROY_SCRIPT"
    echo ">>> AI Server destroyed!"
else
    echo "!!! Warning: destroy_ai.sh not found, skipping AI Server destroy."
fi

echo ""
echo "================================"
echo "  DESTROY PROCESS COMPLETED"
echo "================================"
