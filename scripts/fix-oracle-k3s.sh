#!/bin/bash

# Comprehensive fix script for Oracle Cloud K3s connection issues

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
print_info "  Oracle Cloud K3s Connection Fix"
print_info "=========================================="
echo ""

# Get VM IP
VM_IP=""
if [ -f ~/.kube/config ]; then
    VM_IP=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null | sed 's|https\?://||' | sed 's|:.*||' || echo "")
fi

if [ -z "$VM_IP" ]; then
    read -p "Enter your Oracle Cloud VM IP address: " VM_IP
fi

if [ -z "$VM_IP" ]; then
    print_error "VM IP is required!"
    exit 1
fi

print_info "Using VM IP: $VM_IP"
echo ""

# Get SSH credentials
read -p "Enter SSH username (usually 'ubuntu' or 'opc'): " SSH_USER
read -p "Enter path to private key file: " PRIVATE_KEY

if [ ! -f "$PRIVATE_KEY" ]; then
    print_error "Private key file not found: $PRIVATE_KEY"
    exit 1
fi

chmod 600 "$PRIVATE_KEY"

# Test SSH connection
print_info "Testing SSH connection..."
if ! ssh -i "$PRIVATE_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
    print_error "Cannot connect via SSH!"
    print_info "Check:"
    echo "  - VM is running in Oracle Cloud Console"
    echo "  - Security List allows SSH (port 22)"
    echo "  - Correct username and key file"
    exit 1
fi

print_success "SSH connection works!"
echo ""

# Create remote fix script
print_info "Creating fix script on VM..."
REMOTE_SCRIPT=$(cat << 'REMOTE_EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "Fixing K3s Configuration on Oracle Cloud"
echo "=========================================="
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "")
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(hostname -I | awk '{print $1}')
fi

echo "Detected public IP: $PUBLIC_IP"
echo ""

# Check K3s status
echo "Step 1: Checking K3s status..."
if sudo systemctl is-active --quiet k3s; then
    echo "✅ K3s is running"
    sudo systemctl status k3s --no-pager | head -5
else
    echo "❌ K3s is NOT running"
    echo "Starting K3s..."
    sudo systemctl start k3s
    sudo systemctl enable k3s
    sleep 5
    if sudo systemctl is-active --quiet k3s; then
        echo "✅ K3s started successfully"
    else
        echo "❌ Failed to start K3s"
        sudo systemctl status k3s --no-pager
        exit 1
    fi
fi
echo ""

# Check if K3s is listening on all interfaces
echo "Step 2: Checking K3s network configuration..."
K3S_LISTEN=$(sudo ss -tlnp | grep :6443 || echo "")
if [ -z "$K3S_LISTEN" ]; then
    echo "❌ K3s is not listening on port 6443"
    echo "This is a problem - K3s may need to be reinstalled"
else
    echo "✅ K3s is listening:"
    echo "$K3S_LISTEN"
    
    # Check if it's listening on 0.0.0.0 or specific IP
    if echo "$K3S_LISTEN" | grep -q "0.0.0.0:6443"; then
        echo "✅ K3s is listening on all interfaces (0.0.0.0)"
    else
        echo "⚠️  K3s may be listening on a specific interface"
    fi
fi
echo ""

# Check firewall
echo "Step 3: Checking firewall configuration..."
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(sudo ufw status | head -1 || echo "inactive")
    if echo "$UFW_STATUS" | grep -q "active"; then
        echo "⚠️  UFW firewall is active"
        echo "Checking if port 6443 is allowed..."
        if sudo ufw status | grep -q "6443"; then
            echo "✅ Port 6443 is in UFW rules"
        else
            echo "❌ Port 6443 is NOT in UFW rules"
            echo "Adding UFW rule for port 6443..."
            sudo ufw allow 6443/tcp
            echo "✅ UFW rule added"
        fi
    else
        echo "✅ UFW firewall is not active"
    fi
else
    echo "ℹ️  UFW not installed"
fi

# Check iptables
echo ""
echo "Checking iptables..."
if sudo iptables -L -n | grep -q "6443"; then
    echo "✅ Port 6443 found in iptables rules"
else
    echo "⚠️  Port 6443 not explicitly in iptables (may be handled by default policy)"
fi
echo ""

# Configure K3s to listen on all interfaces (if needed)
echo "Step 4: Ensuring K3s listens on all interfaces..."
K3S_CONFIG="/etc/rancher/k3s/k3s.yaml"
K3S_SERVICE="/etc/systemd/system/k3s.service"

# Check current K3s service configuration
if [ -f "$K3S_SERVICE" ]; then
    if grep -q "K3S_KUBECONFIG_MODE" "$K3S_SERVICE" || grep -q "bind-address" "$K3S_SERVICE"; then
        echo "ℹ️  K3s service has custom configuration"
    else
        echo "ℹ️  K3s service using default configuration"
    fi
fi

# Check if we need to add bind-address
if ! sudo ss -tlnp | grep -q "0.0.0.0:6443"; then
    echo "⚠️  K3s may not be listening on all interfaces"
    echo "Attempting to configure K3s to listen on all interfaces..."
    
    # Create systemd override
    sudo mkdir -p /etc/systemd/system/k3s.service.d/
    sudo tee /etc/systemd/system/k3s.service.d/override.conf > /dev/null << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s server --bind-address 0.0.0.0 --tls-san PUBLIC_IP_PLACEHOLDER
EOF
    
    # Replace placeholder with actual IP
    sudo sed -i "s/PUBLIC_IP_PLACEHOLDER/$PUBLIC_IP/g" /etc/systemd/system/k3s.service.d/override.conf
    
    echo "✅ Created systemd override"
    echo "Reloading systemd and restarting K3s..."
    sudo systemctl daemon-reload
    sudo systemctl restart k3s
    sleep 10
    
    if sudo systemctl is-active --quiet k3s; then
        echo "✅ K3s restarted successfully"
        echo "Checking if it's now listening on all interfaces..."
        sleep 3
        if sudo ss -tlnp | grep -q "0.0.0.0:6443"; then
            echo "✅ K3s is now listening on all interfaces!"
        else
            echo "⚠️  K3s may still not be listening on all interfaces"
        fi
    else
        echo "❌ K3s failed to restart"
        sudo systemctl status k3s --no-pager
        # Restore original
        sudo rm -f /etc/systemd/system/k3s.service.d/override.conf
        sudo systemctl daemon-reload
        sudo systemctl restart k3s
    fi
else
    echo "✅ K3s is already listening on all interfaces"
fi
echo ""

# Final verification
echo "Step 5: Final verification..."
echo "K3s status:"
sudo systemctl status k3s --no-pager | head -10
echo ""

echo "Listening ports:"
sudo ss -tlnp | grep :6443 || echo "Port 6443 not found in listening ports"
echo ""

echo "K3s node status:"
sudo k3s kubectl get nodes 2>/dev/null || echo "Cannot get nodes (this is expected if accessed from outside)"
echo ""

echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify Security List in Oracle Cloud allows port 6443"
echo "2. Test connection from your local machine:"
echo "   kubectl cluster-info"
echo "3. If still not working, check Oracle Cloud Console:"
echo "   - VM is running"
echo "   - Security List has ingress rule for TCP 6443"
echo "   - Source should be 0.0.0.0/0 or your IP"
REMOTE_EOF
)

# Copy script to VM
print_info "Copying fix script to VM..."
echo "$REMOTE_SCRIPT" | ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "cat > /tmp/fix-k3s.sh && chmod +x /tmp/fix-k3s.sh"

# Run the script
print_info "Running fix script on VM..."
echo ""
ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "bash /tmp/fix-k3s.sh"

echo ""
print_info "Retrieving updated kubeconfig..."
KUBECONFIG_CONTENT=$(ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "sudo cat /etc/rancher/k3s/k3s.yaml" 2>/dev/null)

if [ -n "$KUBECONFIG_CONTENT" ]; then
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
    
    # Test connection
    print_info "Testing kubectl connection..."
    sleep 3
    if timeout 15 kubectl cluster-info >/dev/null 2>&1; then
        print_success "✅ Connection successful!"
        echo ""
        kubectl get nodes
        echo ""
        print_success "You can now run: ./scripts/deploy-to-oracle.sh"
    else
        print_warning "Connection test failed, but K3s should be configured correctly"
        echo ""
        print_info "Please verify:"
        echo "  1. Oracle Cloud Security List has ingress rule for TCP port 6443"
        echo "  2. Source should be 0.0.0.0/0 (or your IP)"
        echo "  3. Wait a minute and try: kubectl get nodes"
        echo ""
        print_info "To check Security List:"
        echo "  Oracle Cloud Console → Networking → Virtual Cloud Networks"
        echo "  → Your VCN → Security Lists → Default Security List"
        echo "  → Ingress Rules → Add rule for TCP 6443"
    fi
else
    print_error "Could not retrieve kubeconfig"
fi

echo ""
