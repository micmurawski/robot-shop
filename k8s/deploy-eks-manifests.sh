#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# REPO and TAG are used by envsubst inside manifests.
# For ECR-backed Robot Shop services, we replace tag references with
# digest-pinned references resolved from ECR to ensure immutable deploys.
export REPO="${REPO:-189429133920.dkr.ecr.us-east-1.amazonaws.com}"
export TAG="${TAG:-latest}"
AWS_REGION="${AWS_REGION:-us-east-1}"
NAMESPACE="${NAMESPACE:-application}"
get_repo_name_for_service() {
  local service="$1"
  case "${service}" in
    cart|catalogue|dispatch|mysql|payment|ratings|shipping|user|web)
      echo "robot-shop-${service}"
      ;;
    mongodb)
      echo "robot-shop-mongo"
      ;;
    *)
      # Services that don't use ECR images in these manifests (e.g. redis/rabbitmq).
      echo ""
      ;;
  esac
}

get_latest_digest() {
  local repo_name="$1"
  aws ecr describe-images \
    --region "${AWS_REGION}" \
    --repository-name "${repo_name}" \
    --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageDigest' \
    --output text
}

echo "-------------------------------------------"
echo "Deploying Robot Shop Kubernetes manifests"
echo "REPO: ${REPO}"
echo "TAG:  ${TAG}"
echo "-------------------------------------------"

services=("mysql" "mongodb" "rabbitmq" "redis" "cart" "catalogue" "dispatch" "payment" "ratings" "user" "web" "shipping")
for service in "${services[@]}"; do
  rendered_manifest="$(envsubst < "${SCRIPT_DIR}/manifests/${service}.yaml")"

  repo_name="$(get_repo_name_for_service "${service}")"
  if [[ -n "${repo_name}" ]]; then
    digest="$(get_latest_digest "${repo_name}")"
    if [[ -z "${digest}" || "${digest}" == "None" ]]; then
      echo "No digest found for '${repo_name}', keeping tag-based image in '${service}'."
    else
      tagged_image="${REPO}/${repo_name}:${TAG}"
      digest_image="${REPO}/${repo_name}@${digest}"
      rendered_manifest="${rendered_manifest//${tagged_image}/${digest_image}}"
      echo "Using digest image for '${service}': ${digest_image}"
    fi
  fi

  printf '%s\n' "${rendered_manifest}" | kubectl apply -f -
done

kubectl apply -f ${SCRIPT_DIR}/manifests/serviceprofiles/ -n ${NAMESPACE}

echo "-------------------------------------------"
echo "✅ Manifests applied. Use 'kubectl get pods -n application' to watch rollout."
echo "-------------------------------------------"

