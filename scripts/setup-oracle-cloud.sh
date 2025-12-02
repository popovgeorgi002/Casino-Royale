#!/bin/bash

# Oracle Cloud Infrastructure Setup Script
# Automates K3s installation and configuration

set -e

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
print_info "  Oracle Cloud K3s Setup"
print_info "=========================================="
echo ""

# Get VM details
read -p "Enter your Oracle Cloud VM IP address: " VM_IP
read -p "Enter SSH username (usually 'ubuntu' or 'opc'): " SSH_USER
read -p "Enter path to your private key file: " PRIVATE_KEY

if [ ! -f "$PRIVATE_KEY" ]; then
    print_error "Private key file not found: $PRIVATE_KEY"
    exit 1
fi

# Set correct permissions
chmod 600 "$PRIVATE_KEY"

print_info "Testing SSH connection..."
if ! ssh -i "$PRIVATE_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "echo 'Connection successful'" 2>/dev/null; then
    print_error "Cannot connect to VM. Please check:"
    echo "  - IP address: $VM_IP"
    echo "  - Username: $SSH_USER"
    echo "  - Private key: $PRIVATE_KEY"
    echo "  - Security List allows SSH (port 22)"
    exit 1
fi

print_success "SSH connection successful!"
echo ""

# Create setup script
print_info "Creating setup script..."
cat > /tmp/k3s-setup-remote.sh << 'REMOTE_SCRIPT'
#!/bin/bash
set -e

echo "=========================================="
echo "Installing K3s on Oracle Cloud VM"
echo "=========================================="
echo ""

echo "Step 1: Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo ""
echo "Step 2: Installing K3s..."
curl -sfL https://get.k3s.io | sh -

echo ""
echo "Step 3: Waiting for K3s to start..."
sleep 15

echo ""
echo "Step 4: Checking K3s status..."
sudo systemctl status k3s --no-pager | head -10

echo ""
echo "Step 5: Verifying installation..."
if sudo k3s kubectl get nodes > /dev/null 2>&1; then
    echo "✅ K3s is running!"
    sudo k3s kubectl get nodes
else
    echo "❌ K3s installation may have issues"
    exit 1
fi

echo ""
echo "=========================================="
echo "K3s Installation Complete!"
echo "=========================================="
echo ""
echo "Your kubeconfig:"
echo "---"
sudo cat /etc/rancher/k3s/k3s.yaml
echo "---"
echo ""
echo "To configure kubectl on your local machine:"
echo "  1. Copy the kubeconfig above"
echo "  2. Replace '127.0.0.1' with '$VM_IP'"
echo "  3. Save to ~/.kube/config"
REMOTE_SCRIPT

# Copy and execute setup script
print_info "Copying setup script to VM..."
scp -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no /tmp/k3s-setup-remote.sh "$SSH_USER@$VM_IP:/tmp/k3s-setup-remote.sh"

print_info "Running setup script on VM (this may take 2-3 minutes)..."
ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "chmod +x /tmp/k3s-setup-remote.sh && bash /tmp/k3s-setup-remote.sh"

echo ""
print_success "K3s installation complete!"
echo ""

# Get kubeconfig
print_info "Retrieving kubeconfig..."
KUBECONFIG_CONTENT=$(ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "sudo cat /etc/rancher/k3s/k3s.yaml")

# Replace localhost with VM IP
KUBECONFIG_CONTENT=$(echo "$KUBECONFIG_CONTENT" | sed "s/127.0.0.1/$VM_IP/g")
KUBECONFIG_CONTENT=$(echo "$KUBECONFIG_CONTENT" | sed "s/localhost/$VM_IP/g")

# Save to local kubeconfig
print_info "Configuring kubectl on local machine..."
mkdir -p ~/.kube
echo "$KUBECONFIG_CONTENT" > ~/.kube/config-oracle-cloud
chmod 600 ~/.kube/config-oracle-cloud

# Backup existing config if it exists
if [ -f ~/.kube/config ]; then
    print_warning "Backing up existing ~/.kube/config to ~/.kube/config.backup"
    cp ~/.kube/config ~/.kube/config.backup
fi

# Use new config
cp ~/.kube/config-oracle-cloud ~/.kube/config

# Test connection
print_info "Testing kubectl connection..."
sleep 2
if kubectl get nodes > /dev/null 2>&1; then
    print_success "kubectl is configured and working!"
    echo ""
    kubectl get nodes
    echo ""
    print_info "Current context:"
    kubectl config current-context
else
    print_warning "kubectl connection test failed, but config is saved to ~/.kube/config"
    print_info "You can test manually with: kubectl get nodes"
fi

# Cleanup
rm -f /tmp/k3s-setup-remote.sh

echo ""
print_info "=========================================="
print_success "  Setup Complete!"
print_info "=========================================="
echo ""
print_info "Next steps:"
echo "  1. Verify connection: kubectl get nodes"
echo "  2. Create namespace: kubectl create namespace microservices"
echo "  3. Deploy services: kubectl apply -f <service>/k8s/"
echo ""
print_info "Your kubeconfig is saved to: ~/.kube/config"
print_info "Original config backed up to: ~/.kube/config.backup (if existed)"
echo ""
