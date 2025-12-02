#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# PID file to track running processes (for front-end and port-forwards)
PID_FILE="$PROJECT_ROOT/.start-all.pids"
NAMESPACE="microservices"

# Function to check for npm/node
check_npm() {
    # Check if npm is available
    if command -v npm >/dev/null 2>&1; then
        return 0
    fi
    
    # Check for nvm
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        print_info "Loading nvm..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$HOME/.bashrc" ] && \. "$HOME/.bashrc"
        
        if command -v npm >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Check common installation paths
    if [ -f "/usr/bin/npm" ]; then
        export PATH="/usr/bin:$PATH"
        if command -v npm >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    if [ -f "/usr/local/bin/npm" ]; then
        export PATH="/usr/local/bin:$PATH"
        if command -v npm >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    return 1
}

# Function to check for kubectl
check_kubectl() {
    if command -v kubectl >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Function to check if Kubernetes service is running
check_k8s_service() {
    local service_name=$1
    if kubectl get deployment "$service_name" -n "$NAMESPACE" >/dev/null 2>&1; then
        local ready=$(kubectl get deployment "$service_name" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
        local desired=$(kubectl get deployment "$service_name" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null)
        if [ "$ready" = "$desired" ] && [ -n "$ready" ] && [ "$ready" != "0" ]; then
            return 0
        fi
    fi
    return 1
}

# Function to print colored messages
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

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for a service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    print_info "Waiting for $service_name to be ready..."
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

# Function to start port-forwarding
start_port_forward() {
    local service_name=$1
    local local_port=$2
    local service_port=$3
    local log_file="$PROJECT_ROOT/logs/port-forward-${service_name}.log"

    mkdir -p "$PROJECT_ROOT/logs"

    if check_port $local_port; then
        print_warning "Port $local_port is already in use for $service_name port-forward"
        # Verify it's actually working
        if curl -s --max-time 2 "http://localhost:$local_port/health" > /dev/null 2>&1; then
            print_success "Port-forward for $service_name is already active and working"
            return 0
        else
            print_warning "Port $local_port is in use but not responding, killing existing process..."
            lsof -ti :$local_port | xargs kill -9 2>/dev/null || true
            sleep 1
        fi
    fi

    print_info "Starting port-forward for $service_name (localhost:$local_port -> $service_name:$service_port)..."
    kubectl port-forward -n "$NAMESPACE" "svc/$service_name" "$local_port:$service_port" > "$log_file" 2>&1 &
    local pid=$!
    
    # Wait for port-forward to be established
    local max_wait=10
    local wait_count=0
    while [ $wait_count -lt $max_wait ]; do
        if kill -0 "$pid" 2>/dev/null && check_port $local_port; then
            # Try to connect to verify it's working
            if curl -s --max-time 2 "http://localhost:$local_port/health" > /dev/null 2>&1; then
                echo "$pid|port-forward-$service_name|$local_port" >> "$PID_FILE"
                print_success "Port-forward started for $service_name (PID: $pid)"
                return 0
            fi
        fi
        sleep 1
        wait_count=$((wait_count + 1))
    done

    # Check if process is still running
    if kill -0 "$pid" 2>/dev/null; then
        echo "$pid|port-forward-$service_name|$local_port" >> "$PID_FILE"
        print_warning "Port-forward started for $service_name but may not be fully ready yet (PID: $pid)"
        return 0
    else
        print_error "Failed to start port-forward for $service_name"
        if [ -f "$log_file" ]; then
            print_info "Check logs: $log_file"
        fi
        return 1
    fi
}

# Function to start a local service (front-end only)
start_local_service() {
    local service_dir=$1
    local service_name=$2
    local port=$3
    local log_file="$PROJECT_ROOT/logs/${service_name}.log"

    mkdir -p "$PROJECT_ROOT/logs"

    if [ ! -d "$service_dir" ]; then
        print_error "Directory $service_dir does not exist!"
        return 1
    fi

    if check_port $port; then
        print_warning "$service_name (port $port) is already running"
        return 0
    fi

    print_info "Starting $service_name on port $port..."

    if [ ! -d "$service_dir/node_modules" ]; then
        print_warning "$service_name: node_modules not found. Installing dependencies..."
        cd "$service_dir"
        if ! npm install; then
            print_error "Failed to install dependencies for $service_name"
            cd "$PROJECT_ROOT"
            return 1
        fi
        cd "$PROJECT_ROOT"
    fi

    cd "$service_dir"
    nohup npm run dev > "$log_file" 2>&1 &
    local pid=$!
    cd "$PROJECT_ROOT"

    echo "$pid|$service_name|$port" >> "$PID_FILE"
    print_success "$service_name started (PID: $pid, Port: $port)"
    print_info "Logs: $log_file"
}

# Function to stop all services
stop_all() {
    if [ ! -f "$PID_FILE" ]; then
        print_warning "No local services are running (PID file not found)"
        return 0
    fi

    print_info "Stopping all local services and port-forwards..."
    while IFS='|' read -r pid service_name port; do
        if kill -0 "$pid" 2>/dev/null; then
            print_info "Stopping $service_name (PID: $pid)..."
            kill "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
            print_success "$service_name stopped"
        else
            print_warning "$service_name (PID: $pid) was not running"
        fi
    done < "$PID_FILE"

    rm -f "$PID_FILE"
    print_success "All local services stopped"
}

# Function to show status
show_status() {
    print_info "Service Status:"
    echo ""
    
    # Check Kubernetes services
    if check_kubectl; then
        print_info "Kubernetes Services (namespace: $NAMESPACE):"
        echo ""
        printf "%-20s %-15s %s\n" "SERVICE" "STATUS" "REPLICAS"
        echo "------------------------------------------------------------"
        
        for service in user-service auth-service api-gateway deposit-service; do
            if check_k8s_service "$service"; then
                local ready=$(kubectl get deployment "$service" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
                local desired=$(kubectl get deployment "$service" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null)
                printf "%-20s %-15s %s\n" "$service" "${GREEN}RUNNING${NC}" "$ready/$desired"
            else
                printf "%-20s %-15s %s\n" "$service" "${RED}NOT RUNNING${NC}" "-"
            fi
        done
        echo ""
    else
        print_warning "kubectl not found - cannot check Kubernetes services"
        echo ""
    fi
    
    # Check local services
    print_info "Local Services:"
    echo ""
    if [ ! -f "$PID_FILE" ] || [ ! -s "$PID_FILE" ]; then
        print_warning "No local services are running"
        return 0
    fi

    printf "%-25s %-10s %-10s %s\n" "SERVICE" "PID" "PORT" "STATUS"
    echo "------------------------------------------------------------"
    
    while IFS='|' read -r pid service_name port; do
        if kill -0 "$pid" 2>/dev/null; then
            status="${GREEN}RUNNING${NC}"
        else
            status="${RED}STOPPED${NC}"
        fi
        printf "%-25s %-10s %-10s %s\n" "$service_name" "$pid" "$port" "$status"
    done < "$PID_FILE"
}

# Function to show logs
show_logs() {
    local service_name=$1
    local log_file="$PROJECT_ROOT/logs/${service_name}.log"
    
    if [ ! -f "$log_file" ]; then
        print_error "Log file not found: $log_file"
        return 1
    fi

    print_info "Showing logs for $service_name (Ctrl+C to exit):"
    tail -f "$log_file"
}

# Function to check Kubernetes cluster
check_k8s_cluster() {
    if ! check_kubectl; then
        print_warning "kubectl not found - Kubernetes services cannot be checked"
        return 1
    fi

    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_warning "Kubernetes cluster is not accessible"
        return 1
    fi

    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        print_warning "Namespace '$NAMESPACE' does not exist"
        print_info "Creating namespace..."
        kubectl create namespace "$NAMESPACE"
    fi

    return 0
}

# Main execution
main() {
    # Check for npm/node first
    if ! check_npm; then
        print_error "npm is not found in PATH!"
        echo ""
        print_info "Please install Node.js and npm, or ensure they are in your PATH."
        echo ""
        print_info "Installation options:"
        echo "  1. Using nvm (recommended):"
        echo "     curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "     source ~/.bashrc"
        echo "     nvm install 20"
        echo ""
        echo "  2. Using package manager:"
        echo "     Ubuntu/Debian: sudo apt-get install nodejs npm"
        echo "     Fedora: sudo dnf install nodejs npm"
        echo "     Arch: sudo pacman -S nodejs npm"
        echo ""
        echo "  3. If using nvm, make sure to run:"
        echo "     source ~/.nvm/nvm.sh"
        echo "     before running this script"
        echo ""
        exit 1
    fi
    
    # Verify npm is working
    local npm_version=$(npm --version 2>/dev/null)
    local node_version=$(node --version 2>/dev/null)
    
    if [ -z "$npm_version" ]; then
        print_error "npm is not working properly"
        exit 1
    fi
    
    print_success "Found npm v$npm_version and node $node_version"
    echo ""

    # Check Kubernetes cluster
    check_k8s_cluster

    # Clear PID file on start
    > "$PID_FILE"

    print_info "=========================================="
    print_info "  Starting Microservices Platform"
    print_info "=========================================="
    echo ""

    # Check Kubernetes backend services
    print_info "Checking Kubernetes backend services..."
    echo ""
    
    local k8s_services_ready=true
    for service in user-service auth-service api-gateway deposit-service; do
        if check_k8s_service "$service"; then
            print_success "$service is running in Kubernetes"
        else
            print_warning "$service is not running in Kubernetes"
            k8s_services_ready=false
        fi
    done
    
    echo ""
    
    if [ "$k8s_services_ready" = false ]; then
        print_warning "Some Kubernetes services are not running!"
        print_info "To deploy backend services to Kubernetes, run:"
        echo ""
        echo "  # Build and load images:"
        echo "  docker build -t user-service:latest ./user-service"
        echo "  docker build -t auth-service:latest ./auth-service"
        echo "  docker build -t api-gateway:latest ./api-gateway"
        echo "  docker build -t deposit-service:latest ./deposit-service"
        echo ""
        echo "  kind load docker-image user-service:latest --name microservices"
        echo "  kind load docker-image auth-service:latest --name microservices"
        echo "  kind load docker-image api-gateway:latest --name microservices"
        echo "  kind load docker-image deposit-service:latest --name microservices"
        echo ""
        echo "  # Apply Kubernetes resources:"
        echo "  kubectl apply -f user-service/k8s/"
        echo "  kubectl apply -f auth-service/k8s/"
        echo "  kubectl apply -f api-gateway/k8s/"
        echo "  kubectl apply -f deposit-service/k8s/"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Start port-forwards for Kubernetes services
    print_info "Setting up port-forwards for Kubernetes services..."
    echo ""
    
    start_port_forward "user-service" 3000 3000
    sleep 1
    start_port_forward "auth-service" 3001 3001
    sleep 1
    start_port_forward "api-gateway" 3002 3002
    sleep 1
    start_port_forward "deposit-service" 3004 3004
    sleep 2

    # Start front-end locally
    print_info "Starting front-end..."
    if [ ! -d "$PROJECT_ROOT/front-end" ]; then
        print_error "Front-end directory does not exist!"
    else
        local frontend_port=3003
        if check_port $frontend_port; then
            print_warning "Port $frontend_port is in use. Trying to find available port..."
            frontend_port=3004
            while check_port $frontend_port; do
                frontend_port=$((frontend_port + 1))
            done
            print_info "Using port $frontend_port for front-end"
        fi
        
        if [ ! -d "$PROJECT_ROOT/front-end/node_modules" ]; then
            print_warning "Front-end: node_modules not found. Installing dependencies..."
            cd "$PROJECT_ROOT/front-end"
            npm install
            cd "$PROJECT_ROOT"
        fi

        cd "$PROJECT_ROOT/front-end"
        PORT=$frontend_port nohup npm run dev > "$PROJECT_ROOT/logs/front-end.log" 2>&1 &
        local frontend_pid=$!
        cd "$PROJECT_ROOT"
        
        echo "$frontend_pid|front-end|$frontend_port" >> "$PID_FILE"
        print_success "Front-end started (PID: $frontend_pid, Port: $frontend_port)"
        print_info "Logs: $PROJECT_ROOT/logs/front-end.log"
    fi

    echo ""
    print_info "=========================================="
    print_success "All services are starting!"
    print_info "=========================================="
    echo ""
    
    # Wait a bit for port-forwards to be fully established
    print_info "Waiting for port-forwards to be established..."
    sleep 5

    # Check service health via port-forwards
    print_info "Checking service health..."
    wait_for_service "http://localhost:3000/health" "user-service" || print_warning "user-service health check failed (service may still be starting)"
    wait_for_service "http://localhost:3001/health" "auth-service" || print_warning "auth-service health check failed (service may still be starting)"
    wait_for_service "http://localhost:3002/health" "api-gateway" || print_warning "api-gateway health check failed (service may still be starting)"
    wait_for_service "http://localhost:3004/health" "deposit-service" || print_warning "deposit-service health check failed (service may still be starting)"

    echo ""
    print_info "=========================================="
    print_info "  Service URLs:"
    print_info "=========================================="
    
    # Get front-end port from PID file
    local frontend_port=$(grep "front-end" "$PID_FILE" 2>/dev/null | cut -d'|' -f3 || echo "3003")
    
    echo "  User Service:    http://localhost:3000 (via port-forward)"
    echo "  Auth Service:    http://localhost:3001 (via port-forward)"
    echo "  API Gateway:     http://localhost:3002 (via port-forward)"
    echo "  Deposit Service: http://localhost:3004 (via port-forward)"
    echo "  Front-end:       http://localhost:$frontend_port"
    echo ""
    print_info "Backend services are running in Kubernetes"
    print_info "Port-forwards are active to access them locally"
    echo ""
    print_info "To view logs: ./start-all.sh logs <service-name>"
    print_info "To stop all:  ./start-all.sh stop"
    print_info "To see status: ./start-all.sh status"
    echo ""
}

# Handle command line arguments
case "${1:-start}" in
    start)
        main
        ;;
    stop)
        stop_all
        ;;
    status)
        show_status
        ;;
    logs)
        if [ -z "$2" ]; then
            print_error "Please specify a service name"
            echo "Usage: $0 logs <service-name>"
            echo "Available services: front-end, port-forward-user-service, port-forward-auth-service, port-forward-api-gateway"
            exit 1
        fi
        show_logs "$2"
        ;;
    restart)
        stop_all
        sleep 2
        main
        ;;
    *)
        echo "Usage: $0 {start|stop|status|logs|restart}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all services (default)"
        echo "  stop    - Stop all local services and port-forwards"
        echo "  status  - Show status of all services (K8s + local)"
        echo "  logs    - Show logs for a service (requires service name)"
        echo "  restart - Stop and restart all services"
        exit 1
        ;;
esac
