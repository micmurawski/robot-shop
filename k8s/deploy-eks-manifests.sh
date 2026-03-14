#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# REPO and TAG are used by envsubst inside robot-shop-eks.yaml
export REPO="${REPO:-189429133920.dkr.ecr.us-east-1.amazonaws.com}"
export TAG="${TAG:-latest}"

echo "-------------------------------------------"
echo "Deploying Robot Shop Kubernetes manifests"
echo "REPO: ${REPO}"
echo "TAG:  ${TAG}"
echo "-------------------------------------------"

services=("cart" "catalogue" "dispatch" "mongodb" "mysql" "payment" "rabbitmq" "ratings" "redis" "shipping" "user" "web")
for service in "${services[@]}"; do
  envsubst < "${SCRIPT_DIR}/manifests/${service}.yaml" | kubectl apply -f -
done

echo "-------------------------------------------"
echo "✅ Manifests applied. Use 'kubectl get pods -n application' to watch rollout."
echo "-------------------------------------------"