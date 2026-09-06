#!/bin/bash
# ==============================================================================
# Register AWS K3s Cluster (Cluster 2) to Central ArgoCD on rainbowsrv
# ==============================================================================
set -euo pipefail

AWS_MASTER_IP="${1:-}"

if [ -z "${AWS_MASTER_IP}" ]; then
    echo "=========================================================="
    echo "ERROR: Missing AWS Master Public IP argument."
    echo "Do not type the '<' or '>' angle brackets."
    echo
    echo "Usage:"
    echo "  $0 <AWS_MASTER_PUBLIC_IP>"
    echo
    echo "Example (using your AWS IP):"
    echo "  $0 34.224.82.72"
    echo "=========================================================="
    exit 1
fi

echo "=========================================================="
echo "Registering AWS K3s Cluster ($AWS_MASTER_IP) into ArgoCD..."
echo "=========================================================="

export KUBECONFIG="${HOME}/.kube/config"

# 1. Apply the GitOps Root Applications
echo "Applying ArgoCD GitOps Applications..."
kubectl apply -f gitops/argocd-apps/local-apps.yaml
kubectl apply -f gitops/argocd-apps/aws-apps.yaml

echo
echo "=========================================================="
echo "ArgoCD Applications configured successfully!"
echo "=========================================================="
echo "1. Homelab Apps: http://localhost:8001 / http://localhost:8002"
echo "2. AWS Apps:     http://${AWS_MASTER_IP}:30003"
echo "                 http://${AWS_MASTER_IP}:30004"
echo "                 http://${AWS_MASTER_IP}:30005"
echo
echo "View in ArgoCD Web UI: https://localhost:8080"
echo "=========================================================="
