#!/bin/bash

# Simple startup script - starts all services in separate terminal windows
# Requires: xterm, gnome-terminal, or similar terminal emulator

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Detect terminal emulator
if command -v gnome-terminal &> /dev/null; then
    TERMINAL="gnome-terminal"
    TERMINAL_OPTS="--"
elif command -v xterm &> /dev/null; then
    TERMINAL="xterm"
    TERMINAL_OPTS="-e"
else
    echo "Error: No supported terminal emulator found (gnome-terminal or xterm)"
    exit 1
fi

echo "Starting all services in separate terminal windows..."
echo ""

# Start User Service
echo "Starting User Service..."
cd "$PROJECT_ROOT/user-service"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi
$TERMINAL $TERMINAL_OPTS bash -c "cd '$PROJECT_ROOT/user-service' && npm run dev; exec bash" &
sleep 2

# Start Auth Service
echo "Starting Auth Service..."
cd "$PROJECT_ROOT/auth-service"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi
$TERMINAL $TERMINAL_OPTS bash -c "cd '$PROJECT_ROOT/auth-service' && npm run dev; exec bash" &
sleep 2

# Start API Gateway
echo "Starting API Gateway..."
cd "$PROJECT_ROOT/api-gateway"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi
$TERMINAL $TERMINAL_OPTS bash -c "cd '$PROJECT_ROOT/api-gateway' && npm run dev; exec bash" &
sleep 2

# Start Front-end
echo "Starting Front-end..."
cd "$PROJECT_ROOT/front-end"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi
PORT=3003 $TERMINAL $TERMINAL_OPTS bash -c "cd '$PROJECT_ROOT/front-end' && PORT=3003 npm run dev; exec bash" &

echo ""
echo "All services started!"
echo ""
echo "Service URLs:"
echo "  User Service:    http://localhost:3000"
echo "  Auth Service:    http://localhost:3001"
echo "  API Gateway:     http://localhost:3002"
echo "  Front-end:       http://localhost:3003"
echo ""
echo "Close the terminal windows to stop the services."
