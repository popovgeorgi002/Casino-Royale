#!/bin/bash

# Script to help deploy microservices to cloud
# Supports: Oracle Cloud, DigitalOcean, Hetzner, Generic K8s

set -e

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

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v kubectl >/dev/null 2>&1; then
        print_error "kubectl not found!"
        exit 1
    fi
    
    if ! command -v docker >/dev/null 2>&1; then
        print_error "docker not found!"
        exit 1
    fi
    
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Kubernetes cluster not accessible!"
        print_info "Please configure kubectl to point to your cloud cluster"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

build_and_push_images() {
    local registry=$1
    local namespace=$2
    
    print_info "Building Docker images..."
    
    for service in user-service auth-service api-gateway deposit-service; do
        print_info "Building $service..."
        cd "$PROJECT_ROOT/$service"
        docker build -t "$registry/$namespace/$service:latest" .
        print_success "$service built"
    done
    
    cd "$PROJECT_ROOT"
}

update_manifests_for_cloud() {
    local gateway_url=$1
    
    print_info "Updating manifests for cloud deployment..."
    
    # Update front-end to use cloud gateway URL
    if [ -f "$PROJECT_ROOT/front-end/.env.local" ]; then
        echo "NEXT_PUBLIC_GATEWAY_URL=$gateway_url" >> "$PROJECT_ROOT/front-end/.env.local"
    else
        echo "NEXT_PUBLIC_GATEWAY_URL=$gateway_url" > "$PROJECT_ROOT/front-end/.env.local"
    fi
    
    print_success "Manifests updated"
}

deploy_services() {
    print_info "Deploying services to Kubernetes..."
    
    for service in user-service auth-service api-gateway deposit-service; do
        print_info "Deploying $service..."
        kubectl apply -f "$PROJECT_ROOT/$service/k8s/"
        print_success "$service deployed"
    done
    
    print_info "Waiting for services to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/user-service -n microservices || true
    kubectl wait --for=condition=available --timeout=300s deployment/auth-service -n microservices || true
    kubectl wait --for=condition=available --timeout=300s deployment/api-gateway -n microservices || true
    kubectl wait --for=condition=available --timeout=300s deployment/deposit-service -n microservices || true
}

show_status() {
    print_info "Deployment Status:"
    echo ""
    kubectl get pods -n microservices
    echo ""
    kubectl get svc -n microservices
    echo ""
    
    print_info "To access your services:"
    echo "  - Get external IP: kubectl get svc -n microservices"
    echo "  - Or use port-forward: kubectl port-forward -n microservices svc/api-gateway 3002:3002"
}

main() {
    print_info "=========================================="
    print_info "  Cloud Deployment Helper"
    print_info "=========================================="
    echo ""
    
    check_prerequisites
    
    echo "Select deployment option:"
    echo "1) Deploy to existing cluster (images already built)"
    echo "2) Build images and deploy"
    echo "3) Just show status"
    read -p "Choice [1-3]: " choice
    
    case $choice in
        1)
            read -p "Enter API Gateway URL (e.g., https://your-domain.com or http://your-ip:3002): " gateway_url
            update_manifests_for_cloud "$gateway_url"
            deploy_services
            show_status
            ;;
        2)
            read -p "Enter container registry (e.g., docker.io/username or gcr.io/project): " registry
            read -p "Enter namespace/prefix: " namespace
            read -p "Enter API Gateway URL: " gateway_url
            
            build_and_push_images "$registry" "$namespace"
            update_manifests_for_cloud "$gateway_url"
            deploy_services
            show_status
            ;;
        3)
            show_status
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

main
