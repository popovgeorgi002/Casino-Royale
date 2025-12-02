#!/bin/bash

# Quick check script to verify Oracle Cloud setup

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[FAIL]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

VM_IP=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null | sed 's|https\?://||' | sed 's|:.*||' || echo "")

if [ -z "$VM_IP" ]; then
    read -p "Enter VM IP: " VM_IP
fi

echo "Quick Check for VM: $VM_IP"
echo ""

# Check 1: Ping
echo -n "1. Ping test: "
if timeout 2 ping -c 1 "$VM_IP" >/dev/null 2>&1; then
    print_success "VM responds"
else
    print_warning "No ping response (may be blocked)"
fi

# Check 2: SSH
echo -n "2. SSH port (22): "
if timeout 3 nc -z "$VM_IP" 22 2>/dev/null; then
    print_success "Port 22 open"
else
    print_error "Port 22 closed"
fi

# Check 3: Kubernetes API
echo -n "3. Kubernetes API (6443): "
if timeout 5 nc -z "$VM_IP" 6443 2>/dev/null; then
    print_success "Port 6443 open ✅"
else
    print_error "Port 6443 closed ❌"
    echo ""
    print_error "THIS IS THE PROBLEM!"
    echo ""
    echo "Fix: Add Security List rule in Oracle Cloud Console:"
    echo "  - Ingress Rule"
    echo "  - TCP"
    echo "  - Port: 6443"
    echo "  - Source: 0.0.0.0/0"
    echo ""
    echo "See: scripts/verify-security-list.md for detailed steps"
fi

# Check 4: kubectl
echo -n "4. kubectl connection: "
if timeout 10 kubectl cluster-info >/dev/null 2>&1; then
    print_success "Connected ✅"
    kubectl get nodes 2>/dev/null | head -2
else
    print_error "Cannot connect"
fi

echo ""
