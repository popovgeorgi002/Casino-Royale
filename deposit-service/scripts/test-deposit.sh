#!/bin/bash

# Test script for deposit service
# Usage: ./scripts/test-deposit.sh <user-id> <amount-in-cents>

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

GATEWAY_URL="http://localhost:3002"
USER_ID=${1:-"test-user-123"}
AMOUNT=${2:-1000}  # Default: $10.00 (1000 cents)

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

print_header "Testing Deposit Service"
echo ""

# Step 1: Get initial user balance
print_info "Step 1: Getting initial user balance..."
INITIAL_RESPONSE=$(curl -s http://localhost:3002/gateway/users/$USER_ID)
INITIAL_BALANCE=$(echo "$INITIAL_RESPONSE" | grep -oP '"balance":\K[0-9.]+' || echo "0")
print_info "Initial balance: \$$INITIAL_BALANCE"
echo ""

# Step 2: Create deposit
print_info "Step 2: Creating deposit..."
print_info "User ID: $USER_ID"
print_info "Amount: \$$(echo "scale=2; $AMOUNT/100" | bc) ($AMOUNT cents)"
echo ""

DEPOSIT_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/gateway/deposits" \
    -H "Content-Type: application/json" \
    -d "{\"userId\": \"$USER_ID\", \"amount\": $AMOUNT, \"currency\": \"usd\"}")

echo "Response: $DEPOSIT_RESPONSE"
echo ""

# Check if deposit was successful
if echo "$DEPOSIT_RESPONSE" | grep -q '"success":true'; then
    print_success "Deposit created successfully!"
    
    # Extract payment intent ID
    PAYMENT_INTENT_ID=$(echo "$DEPOSIT_RESPONSE" | grep -oP '"paymentIntentId":"\K[^"]+' || echo "")
    NEW_BALANCE=$(echo "$DEPOSIT_RESPONSE" | grep -oP '"updatedBalance":\K[0-9.]+' || echo "")
    
    if [ -n "$PAYMENT_INTENT_ID" ]; then
        print_info "Payment Intent ID: $PAYMENT_INTENT_ID"
    fi
    
    if [ -n "$NEW_BALANCE" ]; then
        print_success "New balance: \$$NEW_BALANCE"
        print_info "Balance increased by: \$$(echo "scale=2; $AMOUNT/100" | bc)"
    fi
    
    echo ""
    
    # Step 3: Verify updated balance
    print_info "Step 3: Verifying updated balance..."
    sleep 1
    UPDATED_RESPONSE=$(curl -s http://localhost:3002/gateway/users/$USER_ID)
    VERIFIED_BALANCE=$(echo "$UPDATED_RESPONSE" | grep -oP '"balance":\K[0-9.]+' || echo "0")
    print_info "Verified balance: \$$VERIFIED_BALANCE"
    
    if [ "$VERIFIED_BALANCE" = "$NEW_BALANCE" ]; then
        print_success "Balance verification successful!"
    else
        echo "Warning: Balance mismatch"
    fi
else
    echo "Deposit failed. Check the error message above."
fi

echo ""
print_header "Test Complete"
