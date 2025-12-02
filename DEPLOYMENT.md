# Local Deployment Guide

This guide explains how to deploy the entire microservices platform locally with web access.

## Prerequisites

1. **Kubernetes Cluster** (Kind, Minikube, or Docker Desktop)
2. **kubectl** configured to access your cluster
3. **Node.js** (v18 or higher) and npm
4. **Docker** (for building images)

## Quick Start

### 1. Deploy Kubernetes Services

First, ensure all backend services are deployed to Kubernetes:

```bash
# Build Docker images
docker build -t user-service:latest ./user-service
docker build -t auth-service:latest ./auth-service
docker build -t api-gateway:latest ./api-gateway
docker build -t deposit-service:latest ./deposit-service

# Load images into Kind cluster
kind load docker-image user-service:latest --name microservices
kind load docker-image auth-service:latest --name microservices
kind load docker-image api-gateway:latest --name microservices
kind load docker-image deposit-service:latest --name microservices

# Apply Kubernetes manifests
kubectl apply -f user-service/k8s/
kubectl apply -f auth-service/k8s/
kubectl apply -f api-gateway/k8s/
kubectl apply -f deposit-service/k8s/
```

### 2. Deploy for Web Access

Run the deployment script:

```bash
./deploy-local.sh start
```

This will:
- Set up port-forwards for all Kubernetes services
- Start the front-end application
- Make everything accessible via web browser

### 3. Access the Application

Once deployed, access the application at:

- **Front-end**: http://localhost:3003 (or the port shown in output)
- **API Gateway**: http://localhost:3002
- **User Service**: http://localhost:3000
- **Auth Service**: http://localhost:3001
- **Deposit Service**: http://localhost:3004

## Service URLs

### Front-end Application
- **URL**: http://localhost:3003
- **Purpose**: Main web interface for users
- **Features**: Login, Registration, Profile, Roulette Game

### API Gateway
- **URL**: http://localhost:3002
- **Purpose**: Single entry point for all API requests
- **Endpoints**:
  - `GET /health` - Health check
  - `POST /gateway/users/create` - Create user
  - `GET /gateway/users/:id` - Get user
  - `PUT /gateway/users/:id` - Update user
  - `POST /deposits` - Create deposit
  - `GET /deposits/:paymentIntentId` - Get deposit status

### User Service
- **URL**: http://localhost:3000
- **Purpose**: Manages user data and balance
- **Endpoints**:
  - `GET /health` - Health check
  - `GET /api/users/:id` - Get user by ID
  - `PUT /api/users/:id` - Update user balance
  - `POST /api/users` - Create user

### Auth Service
- **URL**: http://localhost:3001
- **Purpose**: Handles authentication and authorization
- **Endpoints**:
  - `GET /health` - Health check
  - `POST /api/auth/register` - Register new user
  - `POST /api/auth/login` - Login user
  - `POST /api/auth/refresh` - Refresh access token

### Deposit Service
- **URL**: http://localhost:3004
- **Purpose**: Handles deposits via Stripe
- **Endpoints**:
  - `GET /health` - Health check
  - `POST /api/deposits` - Create deposit
  - `GET /api/deposits/:paymentIntentId` - Get deposit status

## Managing the Deployment

### Stop All Services

```bash
./deploy-local.sh stop
```

### Check Service Status

```bash
kubectl get pods -n microservices
kubectl get svc -n microservices
```

### View Logs

```bash
# Front-end logs
tail -f logs/front-end.log

# Kubernetes service logs
kubectl logs -n microservices deployment/user-service
kubectl logs -n microservices deployment/auth-service
kubectl logs -n microservices deployment/api-gateway
kubectl logs -n microservices deployment/deposit-service
```

### Restart Services

```bash
./deploy-local.sh stop
./deploy-local.sh start
```

## Troubleshooting

### Port Already in Use

If a port is already in use, the script will attempt to kill the process using it. If that fails:

```bash
# Find process using port
lsof -i :3003

# Kill process
kill -9 <PID>
```

### Services Not Accessible

1. Check if port-forwards are running:
   ```bash
   ps aux | grep port-forward
   ```

2. Check if Kubernetes services are running:
   ```bash
   kubectl get pods -n microservices
   ```

3. Check service health:
   ```bash
   curl http://localhost:3002/health
   ```

### Front-end Not Loading

1. Check if front-end is running:
   ```bash
   ps aux | grep "next dev"
   ```

2. Check front-end logs:
   ```bash
   tail -f logs/front-end.log
   ```

3. Verify Node.js is installed:
   ```bash
   node --version
   npm --version
   ```

## Architecture

```
┌─────────────────┐
│   Web Browser   │
│  (localhost)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Front-end     │
│  (Next.js)      │
│  Port: 3003     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  API Gateway    │
│  Port: 3002     │
└────────┬────────┘
         │
    ┌────┴────┬──────────┬──────────┐
    ▼         ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│  User  │ │  Auth  │ │ Deposit│ │  ...   │
│ Service│ │ Service│ │ Service│ │        │
│ :3000  │ │ :3001  │ │ :3004  │ │        │
└────────┘ └────────┘ └────────┘ └────────┘
    │         │          │
    └─────────┴──────────┘
              │
         ┌────▼────┐
         │PostgreSQL│
         │ (K8s)   │
         └─────────┘
```

## Environment Variables

The front-end uses the following environment variables (can be set in `.env.local`):

```bash
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_GATEWAY_URL=http://localhost:3002
```

## Next Steps

- Access the front-end at http://localhost:3003
- Register a new user
- Make a deposit
- Play roulette!
