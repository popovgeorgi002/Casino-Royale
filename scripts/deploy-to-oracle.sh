#!/bin/bash

# Deploy microservices to Oracle Cloud K3s cluster
# Assumes kubectl is already configured

# Don't exit on error immediately - we want to handle connection errors gracefully
set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

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
print_info "  Deploy to Oracle Cloud"
print_info "=========================================="
echo ""

# Check kubectl
if ! command -v kubectl >/dev/null 2>&1; then
    print_error "kubectl not found!"
    print_info "Install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Get VM IP from kubeconfig
VM_IP_FROM_CONFIG=""
if [ -f ~/.kube/config ]; then
    VM_IP_FROM_CONFIG=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null | sed 's|https\?://||' | sed 's|:.*||' || echo "")
fi

# Check connection with better diagnostics
print_info "Checking Kubernetes connection..."
CONNECTION_OK=false
if ! timeout 10 kubectl cluster-info >/dev/null 2>&1; then
    CONNECTION_ERROR=$(timeout 10 kubectl cluster-info 2>&1 || echo "TIMEOUT")
    
    print_error "Cannot connect to Kubernetes cluster!"
    echo ""
    
    # Diagnostic information
    print_info "Diagnostics:"
    if [ -n "$VM_IP_FROM_CONFIG" ]; then
        echo "  Configured server: $VM_IP_FROM_CONFIG"
        
        # Test network connectivity
        print_info "Testing network connectivity..."
        if command -v nc >/dev/null 2>&1; then
            if timeout 3 nc -z "$VM_IP_FROM_CONFIG" 6443 2>/dev/null; then
                print_success "Port 6443 is reachable"
            else
                print_error "Port 6443 is NOT reachable"
                echo "  - Check if VM is running in Oracle Cloud Console"
                echo "  - Verify Security List allows port 6443 (TCP)"
                echo "  - Check if K3s is running on the VM"
            fi
        fi
        
        if command -v ping >/dev/null 2>&1; then
            if timeout 3 ping -c 1 "$VM_IP_FROM_CONFIG" >/dev/null 2>&1; then
                print_success "VM is reachable (ping)"
            else
                print_warning "VM may not be reachable (ping failed)"
            fi
        fi
    else
        print_warning "Could not extract VM IP from kubeconfig"
    fi
    
    echo ""
    print_info "Troubleshooting steps:"
    echo "  1. Run diagnostic script for detailed analysis:"
    echo "     ./scripts/diagnose-oracle-connection.sh"
    echo ""
    echo "  2. Verify K3s is running on the VM:"
    echo "     ssh -i <key> <user>@$VM_IP_FROM_CONFIG 'sudo systemctl status k3s'"
    echo ""
    echo "  3. Check Oracle Cloud Security List allows port 6443:"
    echo "     - Go to Oracle Cloud Console"
    echo "     - Networking → Virtual Cloud Networks → Your VCN"
    echo "     - Security Lists → Default Security List"
    echo "     - Add Ingress Rule: TCP port 6443"
    echo ""
    echo "  4. Reconfigure kubectl using setup script:"
    echo "     ./scripts/setup-oracle-cloud.sh"
    echo ""
    
    # Offer to help reconfigure
    if [ -n "$VM_IP_FROM_CONFIG" ]; then
        read -p "Do you want to try to reconfigure kubectl? (y/n): " RECONFIGURE
        if [ "$RECONFIGURE" = "y" ] || [ "$RECONFIGURE" = "Y" ]; then
            print_info "To reconfigure, you'll need:"
            echo "  - VM IP address"
            echo "  - SSH username (usually 'ubuntu' or 'opc')"
            echo "  - Path to your private key file"
            echo ""
            read -p "Enter VM IP address: " NEW_VM_IP
            read -p "Enter SSH username: " SSH_USER
            read -p "Enter path to private key: " PRIVATE_KEY
            
            if [ -f "$PRIVATE_KEY" ] && [ -n "$NEW_VM_IP" ] && [ -n "$SSH_USER" ]; then
                print_info "Retrieving kubeconfig from VM..."
                KUBECONFIG_CONTENT=$(ssh -i "$PRIVATE_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$NEW_VM_IP" "sudo cat /etc/rancher/k3s/k3s.yaml" 2>/dev/null)
                
                if [ -n "$KUBECONFIG_CONTENT" ]; then
                    # Replace localhost with VM IP
                    KUBECONFIG_CONTENT=$(echo "$KUBECONFIG_CONTENT" | sed "s/127.0.0.1/$NEW_VM_IP/g" | sed "s/localhost/$NEW_VM_IP/g")
                    
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
                    
                    # Test connection again
                    print_info "Testing connection..."
                    sleep 2
                    if timeout 10 kubectl cluster-info >/dev/null 2>&1; then
                        print_success "Connection successful!"
                        # Update VM_IP_FROM_CONFIG for later use
                        VM_IP_FROM_CONFIG="$NEW_VM_IP"
                        CONNECTION_OK=true
                    else
                        print_error "Still cannot connect. Please check:"
                        echo "  - K3s is running on the VM"
                        echo "  - Security List allows port 6443"
                        exit 1
                    fi
                else
                    print_error "Failed to retrieve kubeconfig from VM"
                    exit 1
                fi
            else
                print_error "Invalid input. Please run setup script manually:"
                echo "  ./scripts/setup-oracle-cloud.sh"
                exit 1
            fi
        else
            exit 1
        fi
    else
        print_info "Please run the setup script first:"
        echo "  ./scripts/setup-oracle-cloud.sh"
        exit 1
    fi
else
    # Connection was successful from the start
    CONNECTION_OK=true
    print_success "Connected to cluster!"
    kubectl get nodes
    echo ""
fi

# If we reconfigured, show nodes here too
if [ "$CONNECTION_OK" = "true" ] && [ -n "$RECONFIGURE" ]; then
    kubectl get nodes
    echo ""
fi

# Get VM IP for service URLs
if [ -n "$VM_IP_FROM_CONFIG" ]; then
    print_info "Detected VM IP from kubeconfig: $VM_IP_FROM_CONFIG"
    read -p "Use this IP for service URLs? (y/n) [y]: " USE_DETECTED_IP
    if [ "$USE_DETECTED_IP" != "n" ] && [ "$USE_DETECTED_IP" != "N" ]; then
        VM_IP="$VM_IP_FROM_CONFIG"
        print_info "Using VM IP: $VM_IP"
    else
        read -p "Enter your Oracle Cloud VM public IP: " VM_IP
    fi
else
    read -p "Enter your Oracle Cloud VM public IP: " VM_IP
fi

if [ -z "$VM_IP" ]; then
    print_error "VM IP is required!"
    exit 1
fi
echo ""

# Re-enable exit on error for deployment steps
set -e

# Create namespace
print_info "Creating namespace..."
kubectl create namespace microservices --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespace created"
echo ""

# Update service types to NodePort for Oracle Cloud
print_info "Updating service configurations for Oracle Cloud..."

# Function to update service type
update_service_type() {
    local service_dir=$1
    local service_name=$2
    
    if [ -f "$service_dir/k8s/service.yaml" ]; then
        # Backup original
        cp "$service_dir/k8s/service.yaml" "$service_dir/k8s/service.yaml.backup"
        
        # Update to NodePort
        sed -i 's/type: ClusterIP/type: NodePort/g' "$service_dir/k8s/service.yaml" || true
        
        print_info "Updated $service_name service to NodePort"
    fi
}

# Update all services
update_service_type "$PROJECT_ROOT/user-service" "user-service"
update_service_type "$PROJECT_ROOT/auth-service" "auth-service"
update_service_type "$PROJECT_ROOT/api-gateway" "api-gateway"
update_service_type "$PROJECT_ROOT/deposit-service" "deposit-service"

# Deploy services
print_info "Deploying services..."
echo ""

for service in user-service auth-service api-gateway deposit-service; do
    print_info "Deploying $service..."
    
    if [ -d "$PROJECT_ROOT/$service/k8s" ]; then
        kubectl apply -f "$PROJECT_ROOT/$service/k8s/"
        print_success "$service deployed"
    else
        print_warning "$service/k8s directory not found, skipping..."
    fi
    
    sleep 1
done

echo ""
print_info "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=user-service -n microservices --timeout=120s || print_warning "user-service not ready yet"
kubectl wait --for=condition=ready pod -l app=auth-service -n microservices --timeout=120s || print_warning "auth-service not ready yet"
kubectl wait --for=condition=ready pod -l app=api-gateway -n microservices --timeout=120s || print_warning "api-gateway not ready yet"
kubectl wait --for=condition=ready pod -l app=deposit-service -n microservices --timeout=120s || print_warning "deposit-service not ready yet"

echo ""
print_info "=========================================="
print_success "  Deployment Complete!"
print_info "=========================================="
echo ""

# Show status
print_info "Pod Status:"
kubectl get pods -n microservices
echo ""

print_info "Service Status:"
kubectl get svc -n microservices
echo ""

# Get NodePorts
print_info "Service Access URLs:"
echo ""

API_GATEWAY_PORT=$(kubectl get svc api-gateway -n microservices -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
USER_SERVICE_PORT=$(kubectl get svc user-service -n microservices -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
AUTH_SERVICE_PORT=$(kubectl get svc auth-service -n microservices -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
DEPOSIT_SERVICE_PORT=$(kubectl get svc deposit-service -n microservices -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

if [ "$API_GATEWAY_PORT" != "N/A" ]; then
    echo "  🌐 API Gateway:     http://$VM_IP:$API_GATEWAY_PORT"
    echo "  🔍 Health Check:    http://$VM_IP:$API_GATEWAY_PORT/health"
fi

if [ "$USER_SERVICE_PORT" != "N/A" ]; then
    echo "  👤 User Service:    http://$VM_IP:$USER_SERVICE_PORT"
fi

if [ "$AUTH_SERVICE_PORT" != "N/A" ]; then
    echo "  🔐 Auth Service:   http://$VM_IP:$AUTH_SERVICE_PORT"
fi

if [ "$DEPOSIT_SERVICE_PORT" != "N/A" ]; then
    echo "  💰 Deposit Service: http://$VM_IP:$DEPOSIT_SERVICE_PORT"
fi

echo ""
print_info "Important:"
echo "  1. Make sure Security List allows ports: $API_GATEWAY_PORT, $USER_SERVICE_PORT, $AUTH_SERVICE_PORT, $DEPOSIT_SERVICE_PORT"
echo "  2. Update front-end .env.local with: NEXT_PUBLIC_GATEWAY_URL=http://$VM_IP:$API_GATEWAY_PORT"
echo "  3. Check logs: kubectl logs -n microservices <pod-name>"
echo ""
