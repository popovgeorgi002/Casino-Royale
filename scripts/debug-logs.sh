#!/bin/bash

# Debug script for viewing logs across all microservices
# Usage: ./scripts/debug-logs.sh [service-name] [options]

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

NAMESPACE="microservices"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    print_error "Namespace '$NAMESPACE' does not exist"
    exit 1
fi

# Function to show logs for a specific service
show_service_logs() {
    local service=$1
    local follow=${2:-false}
    local tail=${3:-100}
    
    print_header "Logs for $service"
    
    if kubectl get deployment "$service" -n "$NAMESPACE" >/dev/null 2>&1; then
        if [ "$follow" = "true" ]; then
            print_info "Following logs (Ctrl+C to stop)..."
            kubectl logs -n "$NAMESPACE" deployment/"$service" -f --tail="$tail" --timestamps
        else
            kubectl logs -n "$NAMESPACE" deployment/"$service" --tail="$tail" --timestamps
        fi
    else
        print_error "Deployment '$service' not found"
        return 1
    fi
}

# Function to show all service status
show_status() {
    print_header "Service Status"
    echo ""
    kubectl get pods -n "$NAMESPACE" -o wide
    echo ""
    print_header "Service Health"
    echo ""
    for service in user-service auth-service api-gateway; do
        if kubectl get deployment "$service" -n "$NAMESPACE" >/dev/null 2>&1; then
            local ready=$(kubectl get deployment "$service" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
            local desired=$(kubectl get deployment "$service" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null)
            if [ "$ready" = "$desired" ] && [ -n "$ready" ] && [ "$ready" != "0" ]; then
                print_success "$service: $ready/$desired replicas ready"
            else
                print_error "$service: $ready/$desired replicas ready"
            fi
        fi
    done
}

# Function to show logs from all services
show_all_logs() {
    print_header "All Service Logs (Last 50 lines)"
    echo ""
    for service in user-service auth-service api-gateway; do
        if kubectl get deployment "$service" -n "$NAMESPACE" >/dev/null 2>&1; then
            print_info "=== $service ==="
            kubectl logs -n "$NAMESPACE" deployment/"$service" --tail=50 --timestamps 2>/dev/null || print_error "Could not get logs for $service"
            echo ""
        fi
    done
}

# Function to search logs
search_logs() {
    local pattern=$1
    local service=${2:-""}
    
    print_header "Searching logs for: $pattern"
    echo ""
    
    if [ -z "$service" ]; then
        # Search all services
        for svc in user-service auth-service api-gateway; do
            if kubectl get deployment "$svc" -n "$NAMESPACE" >/dev/null 2>&1; then
                print_info "=== $svc ==="
                kubectl logs -n "$NAMESPACE" deployment/"$svc" --tail=1000 2>/dev/null | grep -i "$pattern" || echo "No matches"
                echo ""
            fi
        done
    else
        # Search specific service
        if kubectl get deployment "$service" -n "$NAMESPACE" >/dev/null 2>&1; then
            kubectl logs -n "$NAMESPACE" deployment/"$service" --tail=1000 2>/dev/null | grep -i "$pattern"
        else
            print_error "Service '$service' not found"
        fi
    fi
}

# Function to show recent errors
show_errors() {
    print_header "Recent Errors (Last 200 lines)"
    echo ""
    for service in user-service auth-service api-gateway; do
        if kubectl get deployment "$service" -n "$NAMESPACE" >/dev/null 2>&1; then
            print_info "=== $service ==="
            kubectl logs -n "$NAMESPACE" deployment/"$service" --tail=200 2>/dev/null | grep -i "error\|exception\|fail" || echo "No errors found"
            echo ""
        fi
    done
}

# Function to exec into a pod
exec_into_pod() {
    local service=$1
    local pod=$(kubectl get pods -n "$NAMESPACE" -l app="$service" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod" ]; then
        print_error "No pod found for service '$service'"
        return 1
    fi
    
    print_info "Executing into pod: $pod"
    kubectl exec -it -n "$NAMESPACE" "$pod" -- /bin/sh
}

# Main menu
case "${1:-help}" in
    logs|log)
        if [ -z "$2" ]; then
            show_all_logs
        else
            show_service_logs "$2" "${3:-false}" "${4:-100}"
        fi
        ;;
    follow|f)
        if [ -z "$2" ]; then
            print_error "Please specify a service name"
            echo "Usage: $0 follow <service-name>"
            exit 1
        fi
        show_service_logs "$2" "true" "${3:-100}"
        ;;
    status|s)
        show_status
        ;;
    search|grep)
        if [ -z "$2" ]; then
            print_error "Please specify a search pattern"
            echo "Usage: $0 search <pattern> [service-name]"
            exit 1
        fi
        search_logs "$2" "${3:-}"
        ;;
    errors|error)
        show_errors
        ;;
    exec|shell)
        if [ -z "$2" ]; then
            print_error "Please specify a service name"
            echo "Usage: $0 exec <service-name>"
            exit 1
        fi
        exec_into_pod "$2"
        ;;
    help|--help|-h)
        echo "Microservices Debugging Tool"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  logs [service]          Show logs (default: all services)"
        echo "  follow [service]       Follow logs in real-time"
        echo "  status                 Show service status"
        echo "  search <pattern>      Search logs for pattern"
        echo "  errors                 Show recent errors from all services"
        echo "  exec <service>        Exec into service pod"
        echo ""
        echo "Examples:"
        echo "  $0 logs                    # Show all logs"
        echo "  $0 logs user-service       # Show user-service logs"
        echo "  $0 follow user-service     # Follow user-service logs"
        echo "  $0 search 'error'          # Search all logs for 'error'"
        echo "  $0 search 'error' auth-service  # Search auth-service logs"
        echo "  $0 errors                  # Show recent errors"
        echo "  $0 exec user-service       # Shell into user-service pod"
        exit 0
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
