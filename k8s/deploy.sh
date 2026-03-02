#!/usr/bin/env bash
set -euo pipefail

# REPO and TAG are used by envsubst inside robot-shop-eks.yaml
export REPO="${REPO:-robotshop}"
export TAG="${TAG:-2.2.0}"

RESET_NAMESPACES="${RESET_NAMESPACES:-false}"

echo "-------------------------------------------"
echo "Deploying Robot Shop Kubernetes manifests"
echo "REPO: ${REPO}"
echo "TAG:  ${TAG}"
echo "Reset namespaces: ${RESET_NAMESPACES}"
echo "-------------------------------------------"

if [[ "${RESET_NAMESPACES}" == "true" ]]; then
  echo "Deleting namespaces 'robot-shop' and 'load' for a clean deploy..."
  kubectl delete namespace robot-shop --ignore-not-found >/dev/null 2>&1 || true
  kubectl delete namespace load --ignore-not-found >/dev/null 2>&1 || true
  # Give the API server a moment to fully register deletion
  sleep 3
fi

echo "Applying manifests..."
envsubst < robot-shop-eks.yaml | kubectl apply -f -
envsubst < load.yaml           | kubectl apply -f -

echo "-------------------------------------------"
echo "✅ Manifests applied. Use 'kubectl get pods -n robot-shop' to watch rollout."
echo "-------------------------------------------"