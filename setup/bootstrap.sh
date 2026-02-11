#!/usr/bin/env bash
set -euo pipefail

# ============================================
# FinPay Enterprise Lab — Bootstrap Script
# ============================================
# Creates Kind clusters, installs the NFS CSI driver
# (required by Octopus K8s Agents), and creates all
# namespaces used in the lab.
#
# Usage: ./setup/bootstrap.sh
# ============================================

info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m   $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
fail()  { echo -e "\033[1;31m[FAIL]\033[0m $*"; exit 1; }

# --- Prereq checks ---
info "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || fail "docker not found"
command -v kind >/dev/null 2>&1   || fail "kind not found (brew install kind)"
command -v kubectl >/dev/null 2>&1 || fail "kubectl not found"
command -v helm >/dev/null 2>&1   || fail "helm not found (brew install helm)"
docker info >/dev/null 2>&1      || fail "Docker daemon not running"
ok "All prerequisites found"

# ============================================
# 1. KIND CLUSTERS
# ============================================
info "Creating Kind clusters..."

for CLUSTER in finpay-dev finpay-prod; do
  if kind get clusters 2>/dev/null | grep -q "^${CLUSTER}$"; then
    warn "Cluster ${CLUSTER} already exists, skipping"
  else
    cat <<KINDCFG | kind create cluster --name "${CLUSTER}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
KINDCFG
    ok "Created ${CLUSTER}"
  fi
done

# ============================================
# 2. NFS CSI DRIVER (required by Octopus K8s Agent)
# ============================================
info "Installing NFS CSI driver..."

for CTX in kind-finpay-dev kind-finpay-prod; do
  info "  → ${CTX}"
  helm upgrade --install --atomic \
    --kube-context "${CTX}" \
    --repo https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts \
    --namespace kube-system \
    --version "v4.*.*" \
    csi-driver-nfs csi-driver-nfs 2>&1 | tail -1
  ok "  NFS driver on ${CTX}"
done

# ============================================
# 3. NAMESPACES
# ============================================
info "Creating namespaces..."

DEV_NAMESPACES=(
  # Platform
  platform-dev platform-staging monitoring
  # Payments
  payments-dev payments-staging fraud-dev fraud-staging
  # Merchants
  merchant-dev merchant-staging kyc-dev kyc-staging
  # Merchant tenants
  merchant-acme-dev merchant-acme-staging
  merchant-euro-dev merchant-euro-staging
  # ArgoCD (for Chapter 7)
  argocd
)

PROD_NAMESPACES=(
  # Platform
  platform-prod monitoring
  # Payments
  payments-prod fraud-prod
  # Merchants
  merchant-prod kyc-prod
  # Merchant tenants
  merchant-acme-prod merchant-euro-prod
)

for NS in "${DEV_NAMESPACES[@]}"; do
  kubectl --context kind-finpay-dev create namespace "${NS}" 2>/dev/null || true
done
ok "Dev cluster namespaces created (${#DEV_NAMESPACES[@]} namespaces)"

for NS in "${PROD_NAMESPACES[@]}"; do
  kubectl --context kind-finpay-prod create namespace "${NS}" 2>/dev/null || true
done
ok "Prod cluster namespaces created (${#PROD_NAMESPACES[@]} namespaces)"

# ============================================
# DONE
# ============================================
echo ""
echo "============================================"
echo "  ✅ Bootstrap Complete"
echo "============================================"
echo ""
echo "  Clusters:"
echo "    kind-finpay-dev   (Development + Staging)"
echo "    kind-finpay-prod  (Production)"
echo ""
echo "  Verify:"
echo "    kubectl cluster-info --context kind-finpay-dev"
echo "    kubectl cluster-info --context kind-finpay-prod"
echo ""
echo "  Next: Follow enterprise-lab.md → 'Setting the Stage'"
echo ""
