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

# PID file to track running processes
PID_FILE="$PROJECT_ROOT/.start-all.pids"

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

# Function to start a service
start_service() {
    local service_dir=$1
    local service_name=$2
    local port=$3
    local log_file="$PROJECT_ROOT/logs/${service_name}.log"

    # Create logs directory if it doesn't exist
    mkdir -p "$PROJECT_ROOT/logs"

    if [ ! -d "$service_dir" ]; then
        print_error "Directory $service_dir does not exist!"
        return 1
    fi

    # Check if port is already in use
    if check_port $port; then
        print_warning "$service_name (port $port) is already running"
        return 0
    fi

    print_info "Starting $service_name on port $port..."

    # Check if node_modules exists
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

    # Start the service
    cd "$service_dir"
    nohup npm run dev > "$log_file" 2>&1 &
    local pid=$!
    cd "$PROJECT_ROOT"

    # Save PID
    echo "$pid|$service_name|$port" >> "$PID_FILE"

    print_success "$service_name started (PID: $pid, Port: $port)"
    print_info "Logs: $log_file"
}

# Function to stop all services
stop_all() {
    if [ ! -f "$PID_FILE" ]; then
        print_warning "No services are running (PID file not found)"
        return 0
    fi

    print_info "Stopping all services..."
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
    print_success "All services stopped"
}

# Function to show status
show_status() {
    print_info "Service Status:"
    echo ""
    
    if [ ! -f "$PID_FILE" ]; then
        print_warning "No services are running"
        return 0
    fi

    printf "%-20s %-10s %-10s %s\n" "SERVICE" "PID" "PORT" "STATUS"
    echo "------------------------------------------------------------"
    
    while IFS='|' read -r pid service_name port; do
        if kill -0 "$pid" 2>/dev/null; then
            status="${GREEN}RUNNING${NC}"
        else
            status="${RED}STOPPED${NC}"
        fi
        printf "%-20s %-10s %-10s %s\n" "$service_name" "$pid" "$port" "$status"
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

    # Clear PID file on start
    > "$PID_FILE"

    print_info "=========================================="
    print_info "  Starting All Microservices"
    print_info "=========================================="
    echo ""

    # Check if services are already running
    if [ -f "$PID_FILE" ] && [ -s "$PID_FILE" ]; then
        print_warning "Some services might already be running"
        read -p "Do you want to stop them and restart? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            stop_all
        fi
    fi

    # Start services in order
    print_info "Starting backend services..."
    
    # 1. User Service (port 3000)
    start_service "$PROJECT_ROOT/user-service" "user-service" 3000
    sleep 2

    # 2. Auth Service (port 3001)
    start_service "$PROJECT_ROOT/auth-service" "auth-service" 3001
    sleep 2

    # 3. API Gateway (port 3002)
    start_service "$PROJECT_ROOT/api-gateway" "api-gateway" 3002
    sleep 2

    # 4. Front-end (port 3003 to avoid conflict with user-service on 3000)
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
            if ! npm install; then
                print_error "Failed to install dependencies for front-end"
                cd "$PROJECT_ROOT"
                return 1
            fi
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
    
    # Wait a bit for services to start
    sleep 3

    # Check service health
    print_info "Checking service health..."
    wait_for_service "http://localhost:3000/health" "user-service" || true
    wait_for_service "http://localhost:3001/health" "auth-service" || true
    wait_for_service "http://localhost:3002/health" "api-gateway" || true

    echo ""
    print_info "=========================================="
    print_info "  Service URLs:"
    print_info "=========================================="
    # Get front-end port from PID file
    local frontend_port=$(grep "front-end" "$PID_FILE" 2>/dev/null | cut -d'|' -f3 || echo "3003")
    
    echo "  User Service:    http://localhost:3000"
    echo "  Auth Service:    http://localhost:3001"
    echo "  API Gateway:     http://localhost:3002"
    echo "  Front-end:       http://localhost:$frontend_port"
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
            echo "Available services: user-service, auth-service, api-gateway, front-end"
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
        echo "  stop    - Stop all running services"
        echo "  status  - Show status of all services"
        echo "  logs    - Show logs for a service (requires service name)"
        echo "  restart - Stop and restart all services"
        exit 1
        ;;
esac
