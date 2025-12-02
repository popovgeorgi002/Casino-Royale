#!/bin/bash

# Test script: Make request to API Gateway and monitor user-service database
# Usage: ./scripts/test-gateway-to-db.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

NAMESPACE="microservices"
GATEWAY_URL="http://localhost:3002"
TEST_USER_ID="test-$(date +%s)-$$"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to check database
check_db() {
    local user_id=$1
    local result=$(kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U user -d userdb -t -c "SELECT id, balance FROM users WHERE id = '$user_id';" 2>/dev/null | tr -d ' ')
    echo "$result"
}

# Function to show all users in DB
show_all_users() {
    print_info "Current users in database:"
    kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U user -d userdb -c "SELECT id, balance FROM users ORDER BY id;" 2>/dev/null
}

print_header "Testing API Gateway → User Service → Database Flow"
echo ""

# Check if port-forward is needed
if ! lsof -Pi :3002 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_error "API Gateway port-forward not active!"
    print_info "Please run: kubectl port-forward -n microservices svc/api-gateway 3002:3002"
    exit 1
fi

# Step 1: Show initial database state
print_header "Step 1: Initial Database State"
show_all_users
echo ""

# Step 2: Make request to API Gateway
print_header "Step 2: Creating User via API Gateway"
print_info "Request: POST $GATEWAY_URL/gateway/users/create"
print_info "Payload: { id: \"$TEST_USER_ID\", balance: 100 }"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/gateway/users/create" \
    -H "Content-Type: application/json" \
    -d "{\"id\": \"$TEST_USER_ID\", \"balance\": 100}" 2>/dev/null)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    print_success "API Gateway responded (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
else
    print_error "API Gateway request failed (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
    exit 1
fi

echo ""
sleep 2  # Wait a moment for database update

# Step 3: Check database after request
print_header "Step 3: Database After Request"
print_info "Checking if user '$TEST_USER_ID' was created in database..."
echo ""

DB_RESULT=$(check_db "$TEST_USER_ID")

if [ -n "$DB_RESULT" ] && [ "$DB_RESULT" != "" ]; then
    print_success "✅ User found in database!"
    echo "Database entry: $DB_RESULT"
    
    # Verify balance
    BALANCE=$(echo "$DB_RESULT" | grep -oP 'balance:\K[0-9]+' || echo "$DB_RESULT" | grep -oP '\|\s*\K[0-9]+' || echo "unknown")
    if [ "$BALANCE" = "100" ]; then
        print_success "✅ Balance is correct: $BALANCE"
    else
        print_error "⚠️  Balance mismatch. Expected: 100, Got: $BALANCE"
    fi
else
    print_error "❌ User NOT found in database!"
    print_info "This could mean:"
    echo "  - Request didn't reach user-service"
    echo "  - Database update failed"
    echo "  - Service communication issue"
fi

echo ""

# Step 4: Show all users again
print_header "Step 4: Final Database State"
show_all_users
echo ""

# Step 5: Test getting user via gateway
print_header "Step 5: Retrieving User via API Gateway"
print_info "Request: GET $GATEWAY_URL/gateway/users/$TEST_USER_ID"
echo ""

GET_RESPONSE=$(curl -s -w "\n%{http_code}" "$GATEWAY_URL/gateway/users/$TEST_USER_ID" 2>/dev/null)
GET_HTTP_CODE=$(echo "$GET_RESPONSE" | tail -n1)
GET_BODY=$(echo "$GET_RESPONSE" | head -n-1)

if [ "$GET_HTTP_CODE" = "200" ]; then
    print_success "User retrieved via API Gateway (HTTP $GET_HTTP_CODE)"
    echo "Response: $GET_BODY"
else
    print_error "Failed to retrieve user (HTTP $GET_HTTP_CODE)"
    echo "Response: $GET_BODY"
fi

echo ""

# Summary
print_header "Test Summary"
if [ -n "$DB_RESULT" ] && [ "$DB_RESULT" != "" ]; then
    print_success "✅ SUCCESS: Database was updated via API Gateway!"
    echo ""
    print_info "Flow verified:"
    echo "  1. API Gateway received request ✓"
    echo "  2. API Gateway forwarded to User Service ✓"
    echo "  3. User Service created user in database ✓"
    echo "  4. User can be retrieved via API Gateway ✓"
else
    print_error "❌ FAILED: Database was not updated"
    echo ""
    print_info "Troubleshooting:"
    echo "  1. Check API Gateway logs: kubectl logs -n microservices deployment/api-gateway -f"
    echo "  2. Check User Service logs: kubectl logs -n microservices deployment/user-service -f"
    echo "  3. Verify service connectivity: kubectl get pods -n microservices"
fi

echo ""
print_info "Test User ID: $TEST_USER_ID"
print_info "To clean up, you can delete the test user from the database"
