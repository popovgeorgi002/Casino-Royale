#!/bin/bash

# Script to show users in auth-service database
# Usage: ./scripts/show-users.sh [options]

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

NAMESPACE="microservices"
DB_NAME="authdb"
DB_USER="user"
DB_PASSWORD="password"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to show all users
show_users() {
    print_header "Users in Auth Service Database"
    echo ""
    
    kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            id,
            email,
            created_at,
            updated_at
        FROM users 
        ORDER BY created_at DESC;
    " 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo ""
        print_info "Total users: $(kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')"
    else
        echo "Error connecting to database"
        return 1
    fi
}

# Function to show users with refresh tokens count
show_users_with_tokens() {
    print_header "Users with Refresh Token Count"
    echo ""
    
    kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            u.id,
            u.email,
            u.created_at,
            COUNT(rt.id) as refresh_tokens_count
        FROM users u
        LEFT JOIN refresh_tokens rt ON u.id = rt.user_id
        GROUP BY u.id, u.email, u.created_at
        ORDER BY u.created_at DESC;
    " 2>/dev/null
}

# Function to show detailed user info
show_user_details() {
    local user_id=$1
    
    if [ -z "$user_id" ]; then
        print_info "Please provide a user ID"
        echo "Usage: $0 details <user-id>"
        return 1
    fi
    
    print_header "User Details: $user_id"
    echo ""
    
    # Show user info
    print_info "User Information:"
    kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            id,
            email,
            created_at,
            updated_at
        FROM users 
        WHERE id = '$user_id';
    " 2>/dev/null
    
    echo ""
    print_info "Refresh Tokens:"
    kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            id,
            token,
            expires_at,
            created_at
        FROM refresh_tokens 
        WHERE user_id = '$user_id'
        ORDER BY created_at DESC;
    " 2>/dev/null
}

# Function to show refresh tokens
show_refresh_tokens() {
    print_header "All Refresh Tokens"
    echo ""
    
    kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            rt.id,
            rt.user_id,
            u.email,
            rt.expires_at,
            rt.created_at,
            CASE 
                WHEN rt.expires_at < NOW() THEN 'EXPIRED'
                ELSE 'ACTIVE'
            END as status
        FROM refresh_tokens rt
        JOIN users u ON rt.user_id = u.id
        ORDER BY rt.created_at DESC;
    " 2>/dev/null
}

# Function to show summary
show_summary() {
    print_header "Auth Service Database Summary"
    echo ""
    
    print_info "Users:"
    kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            COUNT(*) as total_users,
            COUNT(CASE WHEN created_at > NOW() - INTERVAL '24 hours' THEN 1 END) as users_last_24h,
            COUNT(CASE WHEN created_at > NOW() - INTERVAL '7 days' THEN 1 END) as users_last_7d
        FROM users;
    " 2>/dev/null
    
    echo ""
    print_info "Refresh Tokens:"
    kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            COUNT(*) as total_tokens,
            COUNT(CASE WHEN expires_at > NOW() THEN 1 END) as active_tokens,
            COUNT(CASE WHEN expires_at < NOW() THEN 1 END) as expired_tokens
        FROM refresh_tokens;
    " 2>/dev/null
}

# Main menu
case "${1:-users}" in
    users|list)
        show_users
        ;;
    tokens)
        show_refresh_tokens
        ;;
    with-tokens)
        show_users_with_tokens
        ;;
    details|detail)
        show_user_details "$2"
        ;;
    summary|stats)
        show_summary
        ;;
    help|--help|-h)
        echo "Auth Service Database Viewer"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  users          Show all users (default)"
        echo "  tokens         Show all refresh tokens"
        echo "  with-tokens    Show users with refresh token count"
        echo "  details <id>   Show detailed info for a specific user"
        echo "  summary        Show database summary statistics"
        echo ""
        echo "Examples:"
        echo "  $0                    # Show all users"
        echo "  $0 users               # Show all users"
        echo "  $0 tokens              # Show all refresh tokens"
        echo "  $0 details <user-id>   # Show user details"
        echo "  $0 summary             # Show statistics"
        exit 0
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
