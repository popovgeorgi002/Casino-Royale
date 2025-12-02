#!/bin/bash

# Quick script to check users in user-service database
# Usage: ./scripts/check-users.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

NAMESPACE="microservices"

echo "=========================================="
echo "  User Service Database Entries"
echo "=========================================="
echo ""

kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U user -d userdb -c "
    SELECT 
        id,
        balance
    FROM users 
    ORDER BY id;
"

echo ""
echo "Total users: $(kubectl exec -n "$NAMESPACE" deployment/postgres -- psql -U user -d userdb -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')"
