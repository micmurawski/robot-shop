#!/usr/bin/env bash
set -euo pipefail

# REPO and TAG are used by envsubst inside robot-shop-eks.yaml
export REPO="${REPO:-189429133920.dkr.ecr.us-east-1.amazonaws.com}"
export TAG="${TAG:-latest}"

echo "-------------------------------------------"
echo "Deploying Robot Shop Kubernetes manifests"
echo "REPO: ${REPO}"
echo "TAG:  ${TAG}"
echo "-------------------------------------------"

echo "Applying manifests..."
envsubst < robot-shop-eks.yaml | kubectl apply -f -

echo "-------------------------------------------"
echo "✅ Manifests applied. Use 'kubectl get pods -n robot-shop' to watch rollout."
echo "-------------------------------------------"