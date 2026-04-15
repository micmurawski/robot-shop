#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-application}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Rollout options:
# - none (default): digest-pinned apply handles rollout when digest changes
# - all: restart all deployments in the namespace
# - list: restart only deployments listed in ROLLOUT_DEPLOYMENTS (space-separated)
# NOTE: deploy-eks-manifests.sh now resolves latest ECR digests and replaces
# tag-based images with immutable digest image references.
ROLLOUT_MODE="${ROLLOUT_MODE:-none}"
ROLLOUT_DEPLOYMENTS="${ROLLOUT_DEPLOYMENTS:-}"
DEFAULT_ROBOT_SHOP_DEPLOYMENTS=(
  cart catalogue dispatch mongodb mysql payment rabbitmq ratings shipping user web
)

bash -e "${SCRIPT_DIR}/build-and-push.sh"
bash -e "${SCRIPT_DIR}/deploy-eks-manifests.sh"

restart_deployments() {
  local deployments=("$@")
  for deploy in "${deployments[@]}"; do
    echo "Restarting deployment '${deploy}' in namespace '${NAMESPACE}'."
    kubectl rollout restart deployment/"${deploy}" -n "${NAMESPACE}"
  done
}

case "${ROLLOUT_MODE}" in
  none)
    echo "Skipping rollout restart (ROLLOUT_MODE=none)."
    ;;
  all)
    echo "Restarting all deployments in namespace '${NAMESPACE}'."
    kubectl rollout restart deployment -n "${NAMESPACE}"
    ;;
  list)
    if [[ -z "${ROLLOUT_DEPLOYMENTS}" ]]; then
      echo "ROLLOUT_MODE=list requires ROLLOUT_DEPLOYMENTS."
      exit 1
    fi
    # shellcheck disable=SC2206
    selected_deployments=(${ROLLOUT_DEPLOYMENTS})
    restart_deployments "${selected_deployments[@]}"
    ;;
  *)
    echo "Invalid ROLLOUT_MODE='${ROLLOUT_MODE}'. Use: none|all|list"
    exit 1
    ;;
esac
