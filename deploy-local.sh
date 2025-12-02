#!/bin/bash

# Local Deployment Script for Microservices Platform
# This script deploys all services locally and makes them accessible via web

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

NAMESPACE="microservices"
PID_FILE="$PROJECT_ROOT/.deploy-local.pids"

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

check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

kill_port() {
    local port=$1
    if check_port $port; then
        print_warning "Port $port is in use, killing existing process..."
        lsof -ti :$port | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

start_port_forward() {
    local service_name=$1
    local local_port=$2
    local service_port=$3
    
    kill_port $local_port
    
    print_info "Starting port-forward: $service_name (localhost:$local_port -> $service_name:$service_port)"
    kubectl port-forward -n "$NAMESPACE" "svc/$service_name" "$local_port:$service_port" > /dev/null 2>&1 &
    local pid=$!
    
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        echo "$pid|port-forward-$service_name|$local_port" >> "$PID_FILE"
        print_success "Port-forward started for $service_name (PID: $pid)"
        return 0
    else
        print_error "Failed to start port-forward for $service_name"
        return 1
    fi
}

start_frontend() {
    local port=3003
    
    if check_port $port; then
        print_warning "Port $port is in use, trying to find alternative..."
        port=3004
        while check_port $port; do
            port=$((port + 1))
        done
        print_info "Using port $port for front-end"
    fi
    
    if [ ! -d "$PROJECT_ROOT/front-end/node_modules" ]; then
        print_info "Installing front-end dependencies..."
        cd "$PROJECT_ROOT/front-end"
        npm install
        cd "$PROJECT_ROOT"
    fi
    
    print_info "Starting front-end on port $port..."
    cd "$PROJECT_ROOT/front-end"
    PORT=$port nohup npm run dev > "$PROJECT_ROOT/logs/front-end.log" 2>&1 &
    local pid=$!
    cd "$PROJECT_ROOT"
    
    echo "$pid|front-end|$port" >> "$PID_FILE"
    print_success "Front-end started (PID: $pid, Port: $port)"
    
    sleep 5
    if curl -s "http://localhost:$port" > /dev/null 2>&1; then
        print_success "Front-end is accessible at http://localhost:$port"
    else
        print_warning "Front-end may still be starting..."
    fi
    
    echo $port
}

wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    print_info "Waiting for $service_name..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    echo ""
    print_warning "$service_name did not become ready in time"
    return 1
}

stop_all() {
    if [ ! -f "$PID_FILE" ]; then
        print_warning "No services are running"
        return 0
    fi
    
    print_info "Stopping all services..."
    while IFS='|' read -r pid service_name port; do
        if kill -0 "$pid" 2>/dev/null; then
            print_info "Stopping $service_name (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
        fi
    done < "$PID_FILE"
    
    rm -f "$PID_FILE"
    print_success "All services stopped"
}

main() {
    print_info "=========================================="
    print_info "  Local Deployment - Web Access Setup"
    print_info "=========================================="
    echo ""
    
    if ! command -v kubectl >/dev/null 2>&1; then
        print_error "kubectl not found!"
        exit 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm not found!"
        exit 1
    fi
    
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        print_error "Namespace '$NAMESPACE' does not exist!"
        print_info "Please deploy Kubernetes services first"
        exit 1
    fi
    
    mkdir -p "$PROJECT_ROOT/logs"
    > "$PID_FILE"
    
    print_info "Checking Kubernetes services..."
    for service in user-service auth-service api-gateway deposit-service; do
        if kubectl get deployment "$service" -n "$NAMESPACE" >/dev/null 2>&1; then
            print_success "$service is deployed"
        else
            print_error "$service is not deployed!"
            exit 1
        fi
    done
    
    echo ""
    print_info "Setting up port-forwards..."
    start_port_forward "user-service" 3000 3000
    sleep 1
    start_port_forward "auth-service" 3001 3001
    sleep 1
    start_port_forward "api-gateway" 3002 3002
    sleep 1
    start_port_forward "deposit-service" 3004 3004
    sleep 2
    
    echo ""
    print_info "Starting front-end application..."
    local frontend_port=$(start_frontend)
    
    echo ""
    print_info "Waiting for services to be ready..."
    wait_for_service "http://localhost:3000/health" "user-service" || true
    wait_for_service "http://localhost:3001/health" "auth-service" || true
    wait_for_service "http://localhost:3002/health" "api-gateway" || true
    wait_for_service "http://localhost:3004/health" "deposit-service" || true
    
    echo ""
    print_info "=========================================="
    print_success "  Deployment Complete!"
    print_info "=========================================="
    echo ""
    print_info "Web Access URLs:"
    echo ""
    echo "  🌐 Front-end Application:"
    echo "     http://localhost:$frontend_port"
    echo ""
    echo "  🔧 Backend Services (via port-forward):"
    echo "     User Service:    http://localhost:3000"
    echo "     Auth Service:    http://localhost:3001"
    echo "     API Gateway:     http://localhost:3002"
    echo "     Deposit Service: http://localhost:3004"
    echo ""
    print_info "To stop all services: ./deploy-local.sh stop"
    print_info "To view logs: tail -f logs/front-end.log"
    echo ""
}

case "${1:-start}" in
    start)
        main
        ;;
    stop)
        stop_all
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
