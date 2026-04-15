#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Build and deploy Robot Shop to EKS using ECR.
# - Builds all service images
# - Pushes them to ECR
# - Calls the k8s/deploy.sh script, which uses envsubst on robot-shop-eks.yaml
#
# Requirements:
# - AWS CLI configured (AWS_REGION / AWS_PROFILE etc.)
# - Docker logged in locally (this script will log in to ECR)
# - kubectl configured for your EKS cluster
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROBOT_SHOP_ROOT="${SCRIPT_DIR}/.."

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-189429133920}"
TAG="${TAG:-latest}"

# This is what robot-shop-eks.yaml and load-robot-shop.yaml use as ${REPO}
export REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export TAG

folders=("cart" "catalogue" "dispatch" "load-gen" "mongo" "mysql" "payment" "ratings" "shipping" "user" "web")

# Docker has no built-in push retries; ECR blob uploads can fail transiently.
# DOCKER_PUSH_RETRIES: extra attempts after the first failure (default 3 → 4 tries total).
DOCKER_PUSH_RETRIES="${DOCKER_PUSH_RETRIES:-3}"
RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS:-5}"

run_with_retry() {
  local max_attempts=$((1 + DOCKER_PUSH_RETRIES))
  local attempt=1
  local delay="${RETRY_DELAY_SECONDS}"
  while (( attempt <= max_attempts )); do
    if "$@"; then
      return 0
    fi
    if (( attempt == max_attempts )); then
      echo "Command failed after ${max_attempts} attempt(s): $*" >&2
      return 1
    fi
    echo "Attempt ${attempt} failed; retrying in ${delay}s ($((attempt + 1))/${max_attempts})..."
    sleep "${delay}"
    ((attempt++))
  done
}

get_repo_name() {
  local folder="$1"
  case "$folder" in
    load-gen) echo "robot-shop-load-gen" ;;
    *) echo "robot-shop-${folder}" ;;
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
echo "Building and pushing Robot Shop images"
echo "Region:        ${AWS_REGION}"
echo "Account:       ${AWS_ACCOUNT_ID}"
echo "ECR base repo: ${REPO}"
echo "Tag:           ${TAG}"
echo "Deploy mode:   digest-pinned images (resolved during apply)"
echo "-------------------------------------------"

echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Ensuring ECR repositories exist..."
for folder in "${folders[@]}"; do
  repo_name="$(get_repo_name "${folder}")"
  if ! aws ecr describe-repositories --region "${AWS_REGION}" --repository-names "${repo_name}" >/dev/null 2>&1; then
    echo "Creating ECR repo: ${repo_name}"
    aws ecr create-repository --region "${AWS_REGION}" --repository-name "${repo_name}" >/dev/null
  fi
done

echo "Building and pushing service images..."
pushd "${ROBOT_SHOP_ROOT}" >/dev/null
for folder in "${folders[@]}"; do
  repo_name="$(get_repo_name "${folder}")"
  full_image="${REPO}/${repo_name}:${TAG}"
  echo "-------------------------------------------"
  echo "Building ${folder} -> ${full_image}"
  run_with_retry docker build -t "${full_image}" "./${folder}"
  run_with_retry docker push "${full_image}"
  latest_digest="$(get_latest_digest "${repo_name}")"
  echo "Latest digest for ${repo_name}: ${latest_digest}"
done
popd >/dev/null
