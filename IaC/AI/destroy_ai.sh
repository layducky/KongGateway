#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$ROOT_DIR"

terraform destroy -auto-approve

echo "AI Server destroyed"
