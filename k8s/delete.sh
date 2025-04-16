#!/bin/bash

# Set environment variables
export REPO=${REPO:-"robotshop"}
export TAG=${TAG:-"2.2.0"}

echo "Deploying all resources"
envsubst < robot-shop.yaml | kubectl delete -f -

#Wait for services to be ready
#echo "Waiting for services to be ready..."
#kubectl wait --for=condition=available --timeout=100s deployment/web -n robot-shop

# Get the external IP or hostname
#echo "Robot Shop is being deployed. You can access it at:"
#kubectl get ingress robot-shop-ingress -n robot-shop -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 