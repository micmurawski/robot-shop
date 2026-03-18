NAMESPACE="application"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash -e "${SCRIPT_DIR}/build-and-push.sh"
bash -e "${SCRIPT_DIR}/deploy-eks-manifests.sh"
kubectl rollout restart deployment -n $NAMESPACE
