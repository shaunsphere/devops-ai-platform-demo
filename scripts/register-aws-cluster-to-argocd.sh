#!/bin/bash
# ==============================================================================
# Register AWS K3s Cluster (Cluster 2) to Central ArgoCD on rainbowsrv
# ==============================================================================
set -euo pipefail

AWS_MASTER_IP="${1:-}"

if [ -z "${AWS_MASTER_IP}" ]; then
    echo "Usage: $0 <AWS_MASTER_PUBLIC_IP>"
    echo "Example: $0 54.210.12.34"
    exit 1
fi

echo "====================================================="
echo "Registering AWS K3s Cluster ($AWS_MASTER_IP) into ArgoCD..."
echo "====================================================="

# Login to ArgoCD locally
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password "${ARGOCD_PASSWORD}" --insecure --grpc-web || true

echo "Please ensure you have AWS K3s kubeconfig context in your ~/.kube/config"
echo "Registering cluster name: aws-k3s-cluster..."

# Register external cluster with ArgoCD
argocd cluster add aws-k3s --name aws-k3s-cluster --yes || true

echo
echo "Applying GitOps Root Applications..."
kubectl apply -f gitops/argocd-apps/local-apps.yaml
kubectl apply -f gitops/argocd-apps/aws-apps.yaml

echo "ArgoCD multi-cluster registration complete!"
echo "Check status in ArgoCD UI: https://localhost:8080"
