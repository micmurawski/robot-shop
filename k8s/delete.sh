#!/usr/bin/env bash
set -euo pipefail

# Set environment variables
export REPO=${REPO:-189429133920.dkr.ecr.us-east-1.amazonaws.com}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Deleting all resources"
services=("cart" "catalogue" "dispatch" "mongodb" "mysql" "payment" "ratings" "redis" "shipping" "user" "web")
for service in "${services[@]}"; do
  envsubst < "${SCRIPT_DIR}/files/${service}.yaml" | kubectl delete -f -
done
echo "All resources deleted"