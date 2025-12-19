#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$ROOT_DIR"

if [ ! -d ".terraform" ]; then
  terraform init -input=false
fi
terraform apply -auto-approve


AI_IP=$(terraform output -raw public_ip)

if [ -z "$AI_IP" ]; then
  echo "Failed to get AI Server IP" >&2
  exit 1
fi

echo "$AI_IP"
