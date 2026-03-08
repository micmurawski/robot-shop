#!/usr/bin/env bash
# Check what's constraining scheduling: pod count, CPU, or memory.
# Run against your EKS cluster (e.g. from k8s/ with kubectl configured).

set -e

echo "=== Node capacity vs allocatable vs requested ==="
kubectl get nodes -o custom-columns=\
NAME:.metadata.name,\
PODS_ALLOCATABLE:.status.allocatable.pods,\
PODS_CAPACITY:.status.capacity.pods,\
CPU_ALLOCATABLE:.status.allocatable.cpu,\
MEMORY_ALLOCATABLE:.status.allocatable.memory,\
TAINTS:.spec.taints

echo ""
echo "=== Requested resources per node (sum of all pods) ==="
kubectl describe nodes | grep -A 20 "Allocated resources:" || true

echo ""
echo "=== Pod count per node ==="
kubectl get pods -A -o wide | awk '{print $8}' | grep -v NODE | sort | uniq -c | sort -rn

echo ""
echo "=== Taints (nodes that reject pods without matching toleration) ==="
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}'
