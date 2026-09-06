#!/bin/bash
# ==============================================================================
# Setup Local K3s and ArgoCD on rainbowsrv (Ubuntu Homelab Server)
# ==============================================================================
set -euo pipefail

echo "====================================================="
echo "Configuring K3s permissions on rainbowsrv..."
echo "====================================================="

if ! command -v k3s &> /dev/null; then
    echo "Installing K3s..."
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
    echo "K3s installed successfully."
else
    echo "K3s is already installed."
fi

# Ensure user has read permissions to K3s kubeconfig
echo "Setting up ~/.kube/config for user $USER..."
mkdir -p "$HOME/.kube"
sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
sudo chown -R "$USER:$USER" "$HOME/.kube"
chmod 600 "$HOME/.kube/config"
sudo chmod 644 /etc/rancher/k3s/k3s.yaml || true

export KUBECONFIG="$HOME/.kube/config"

echo "Verifying kubectl connection..."
kubectl cluster-info

echo
echo "====================================================="
echo "Installing ArgoCD on local K3s..."
echo "====================================================="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD server pod to become ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

echo
echo "====================================================="
echo "Installing ArgoCD CLI..."
echo "====================================================="
if ! command -v argocd &> /dev/null; then
    sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo chmod +x /usr/local/bin/argocd
    echo "ArgoCD CLI installed to /usr/local/bin/argocd"
fi

echo
echo "====================================================="
echo "ArgoCD Credentials & Access:"
echo "====================================================="
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Username: admin"
echo "Password: ${ARGOCD_PASSWORD}"
echo
echo "To access ArgoCD Web UI, run port-forward:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then open: https://localhost:8080"
echo "====================================================="
