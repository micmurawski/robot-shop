#!/bin/bash

# Set environment variables
export REPO=${REPO:-"your-docker-repo"}
export TAG=${TAG:-"latest"}

# Deploy all resources
kubectl apply -f robot-shop.yaml

# Wait for services to be ready
echo "Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/web -n robot-shop

# Get the external IP or hostname
echo "Robot Shop is being deployed. You can access it at:"
kubectl get ingress robot-shop-ingress -n robot-shop -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 