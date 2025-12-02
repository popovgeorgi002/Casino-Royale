#!/bin/bash

# Diagnostic script for Oracle Cloud Kubernetes connection issues

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info "=========================================="
print_info "  Oracle Cloud Connection Diagnostics"
print_info "=========================================="
echo ""

# Get VM IP from kubeconfig
VM_IP=""
if [ -f ~/.kube/config ]; then
    VM_IP=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null | sed 's|https\?://||' | sed 's|:.*||' || echo "")
fi

if [ -z "$VM_IP" ]; then
    print_error "No VM IP found in kubeconfig"
    print_info "Please run: ./scripts/setup-oracle-cloud.sh"
    exit 1
fi

print_info "Detected VM IP: $VM_IP"
echo ""

# Test 1: Ping test
print_info "Test 1: Checking if VM is reachable (ping)..."
if timeout 3 ping -c 1 "$VM_IP" >/dev/null 2>&1; then
    print_success "VM is reachable via ping"
else
    print_warning "VM is not responding to ping (may be blocked by firewall)"
fi
echo ""

# Test 2: Port 6443 (Kubernetes API)
print_info "Test 2: Checking Kubernetes API port (6443)..."
if command -v nc >/dev/null 2>&1; then
    if timeout 5 nc -z "$VM_IP" 6443 2>/dev/null; then
        print_success "Port 6443 is open and reachable"
    else
        print_error "Port 6443 is NOT reachable"
        echo "  This is the main issue!"
        echo ""
        print_info "Possible causes:"
        echo "  1. Security List doesn't allow port 6443"
        echo "  2. K3s is not running on the VM"
        echo "  3. VM is stopped"
        echo ""
    fi
else
    print_warning "nc (netcat) not installed, skipping port test"
fi
echo ""

# Test 3: SSH access
print_info "Test 3: Checking SSH access..."
read -p "Do you want to test SSH connection? (y/n): " TEST_SSH
if [ "$TEST_SSH" = "y" ] || [ "$TEST_SSH" = "Y" ]; then
    read -p "Enter SSH username (usually 'ubuntu' or 'opc'): " SSH_USER
    read -p "Enter path to private key file: " PRIVATE_KEY
    
    if [ -f "$PRIVATE_KEY" ] && [ -n "$SSH_USER" ]; then
        chmod 600 "$PRIVATE_KEY" 2>/dev/null
        print_info "Testing SSH connection..."
        if ssh -i "$PRIVATE_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "echo 'SSH connection successful'" 2>/dev/null; then
            print_success "SSH connection works!"
            echo ""
            
            # Check K3s status
            print_info "Checking K3s status on VM..."
            K3S_STATUS=$(ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "sudo systemctl is-active k3s 2>/dev/null || echo 'inactive'" 2>/dev/null)
            
            if [ "$K3S_STATUS" = "active" ]; then
                print_success "K3s is running on the VM"
                
                # Try to get kubeconfig
                print_info "Attempting to retrieve kubeconfig..."
                KUBECONFIG_CONTENT=$(ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "sudo cat /etc/rancher/k3s/k3s.yaml" 2>/dev/null)
                
                if [ -n "$KUBECONFIG_CONTENT" ]; then
                    print_success "Kubeconfig retrieved successfully"
                    echo ""
                    print_info "The issue is likely:"
                    echo "  - Security List doesn't allow port 6443 from your IP"
                    echo "  - Or the kubeconfig has wrong IP address"
                    echo ""
                    read -p "Do you want to update your local kubeconfig? (y/n): " UPDATE_CONFIG
                    if [ "$UPDATE_CONFIG" = "y" ] || [ "$UPDATE_CONFIG" = "Y" ]; then
                        # Replace localhost with VM IP
                        KUBECONFIG_CONTENT=$(echo "$KUBECONFIG_CONTENT" | sed "s/127.0.0.1/$VM_IP/g" | sed "s/localhost/$VM_IP/g")
                        
                        # Backup existing config
                        if [ -f ~/.kube/config ]; then
                            cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d_%H%M%S)
                            print_info "Backed up existing config"
                        fi
                        
                        # Save new config
                        mkdir -p ~/.kube
                        echo "$KUBECONFIG_CONTENT" > ~/.kube/config
                        chmod 600 ~/.kube/config
                        
                        print_success "kubeconfig updated!"
                        echo ""
                        print_info "Testing kubectl connection..."
                        sleep 2
                        if timeout 10 kubectl cluster-info >/dev/null 2>&1; then
                            print_success "kubectl connection successful!"
                            kubectl get nodes
                        else
                            print_error "Still cannot connect via kubectl"
                            echo ""
                            print_info "This means port 6443 is blocked by Security List"
                            echo "You need to:"
                            echo "  1. Go to Oracle Cloud Console"
                            echo "  2. Networking → Virtual Cloud Networks → Your VCN"
                            echo "  3. Security Lists → Default Security List"
                            echo "  4. Add Ingress Rule:"
                            echo "     - Source: 0.0.0.0/0 (or your IP)"
                            echo "     - IP Protocol: TCP"
                            echo "     - Destination Port: 6443"
                            echo "     - Description: Kubernetes API"
                        fi
                    fi
                else
                    print_error "Could not retrieve kubeconfig"
                fi
            else
                print_error "K3s is NOT running on the VM"
                echo ""
                print_info "To start K3s, SSH to the VM and run:"
                echo "  sudo systemctl start k3s"
                echo "  sudo systemctl status k3s"
            fi
        else
            print_error "SSH connection failed"
            echo ""
            print_info "Check:"
            echo "  - VM is running in Oracle Cloud Console"
            echo "  - Security List allows SSH (port 22)"
            echo "  - Correct username and key file"
        fi
    else
        print_error "Invalid SSH credentials"
    fi
else
    print_info "Skipping SSH test"
fi

echo ""
print_info "=========================================="
print_info "  Diagnostic Complete"
print_info "=========================================="
echo ""
print_info "Next steps:"
echo "  1. If port 6443 is blocked: Update Security List in Oracle Cloud Console"
echo "  2. If K3s is not running: SSH to VM and start it"
echo "  3. If IP changed: Run ./scripts/setup-oracle-cloud.sh again"
echo "  4. Once fixed, run: ./scripts/deploy-to-oracle.sh"
echo ""
