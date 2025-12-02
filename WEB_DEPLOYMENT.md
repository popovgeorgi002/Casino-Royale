# Web Deployment Quick Start

## Deploy Everything for Web Access

### Option 1: Use the existing start-all script

```bash
./start-all.sh start
```

This will:
- ✅ Check Kubernetes services
- ✅ Set up port-forwards (3000, 3001, 3002, 3004)
- ✅ Start front-end on port 3003
- ✅ Display all accessible URLs

### Option 2: Use the new deploy-local script

```bash
./deploy-local.sh start
```

## Access Your Application

After running either script, access:

### 🌐 Main Application
**Front-end**: http://localhost:3003

Open this URL in your web browser to:
- Register/Login
- View your profile
- Make deposits
- Play roulette

### 🔧 Backend Services (for testing/debugging)
- **API Gateway**: http://localhost:3002
- **User Service**: http://localhost:3000
- **Auth Service**: http://localhost:3001
- **Deposit Service**: http://localhost:3004

## Stop Services

```bash
./start-all.sh stop
# or
./deploy-local.sh stop
```

## Verify Everything is Running

```bash
# Check Kubernetes services
kubectl get pods -n microservices

# Check port-forwards
ps aux | grep port-forward

# Check front-end
curl http://localhost:3003

# Check API Gateway
curl http://localhost:3002/health
```

## Troubleshooting

### Port conflicts
If a port is in use, the script will try to free it automatically. If that fails:

```bash
# Find what's using the port
lsof -i :3003

# Kill it
kill -9 <PID>
```

### Services not accessible
1. Ensure Kubernetes cluster is running
2. Check services are deployed: `kubectl get pods -n microservices`
3. Restart port-forwards: `./start-all.sh stop && ./start-all.sh start`

### Front-end not loading
1. Check logs: `tail -f logs/front-end.log`
2. Verify Node.js: `node --version` (should be v18+)
3. Reinstall dependencies: `cd front-end && npm install`

## Architecture

```
Browser → Front-end (3003) → API Gateway (3002) → Services (3000, 3001, 3004)
```

All services are accessible via `localhost` on their respective ports.
