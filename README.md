# Microservices Platform

A modern microservices-based platform built with Node.js, TypeScript, and Kubernetes. This project demonstrates a scalable architecture with separate services for authentication, user management, and payment processing.

## Video Demo

Watch the platform in action:

<iframe width="560" height="315" src="https://www.youtube.com/embed/QorTxd_Hlfk" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

[Watch on YouTube](https://youtu.be/QorTxd_Hlfk)

## Architecture Overview

The platform consists of the following services:

- **API Gateway** (Port 3002) - Central entry point that routes requests to appropriate services
- **Auth Service** (Port 3001) - Handles user authentication and JWT token management
- **User Service** (Port 3000) - Manages user profiles and balances
- **Deposit Service** (Port 3004) - Processes payments via Stripe integration
- **Front-end** (Port 3003) - Next.js web application

## Technology Stack

- **Backend**: Node.js, Express, TypeScript
- **Database**: PostgreSQL (with Prisma ORM)
- **Authentication**: JWT (JSON Web Tokens)
- **Payment Processing**: Stripe API
- **Frontend**: Next.js 14, React, Tailwind CSS
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Development**: tsx, TypeScript

## Prerequisites

- Node.js 20+ and npm
- Docker and Docker Compose
- Kubernetes cluster (kind, minikube, or cloud-based)
- kubectl configured
- PostgreSQL database (or use provided docker-compose setup)
- Stripe account (for deposit service)

## Quick Start

### 1. Start All Services

The easiest way to start all services is using the provided script:

```bash
./start-all.sh
```

This script will:
- Check for required dependencies (npm, kubectl)
- Verify Kubernetes cluster connectivity
- Start backend services in Kubernetes (via port-forwards)
- Start the front-end locally
- Display service URLs and health status

### 2. Manual Setup

#### Backend Services (Kubernetes)

1. **Build Docker images:**
```bash
docker build -t user-service:latest ./user-service
docker build -t auth-service:latest ./auth-service
docker build -t api-gateway:latest ./api-gateway
docker build -t deposit-service:latest ./deposit-service
```

2. **Load images to Kubernetes (if using kind):**
```bash
kind load docker-image user-service:latest --name microservices
kind load docker-image auth-service:latest --name microservices
kind load docker-image api-gateway:latest --name microservices
kind load docker-image deposit-service:latest --name microservices
```

3. **Apply Kubernetes resources:**
```bash
kubectl apply -f user-service/k8s/
kubectl apply -f auth-service/k8s/
kubectl apply -f api-gateway/k8s/
kubectl apply -f deposit-service/k8s/
```

#### Front-end

```bash
cd front-end
npm install
npm run dev
```

## Service Details

### API Gateway
- **Port**: 3002
- **Health Check**: `http://localhost:3002/health`
- Routes requests to appropriate microservices
- Handles CORS and request proxying

### Auth Service
- **Port**: 3001
- **Health Check**: `http://localhost:3001/health`
- **Endpoints**:
  - `POST /auth/register` - User registration
  - `POST /auth/login` - User login
- Uses PostgreSQL for user storage
- Implements JWT access and refresh tokens

### User Service
- **Port**: 3000
- **Health Check**: `http://localhost:3000/health`
- **Endpoints**:
  - `GET /api/users/:id` - Get user by ID
  - `POST /api/users` - Create user
  - `PUT /api/users/:id` - Update user
  - `DELETE /api/users/:id` - Delete user
- Manages user balances and profiles

### Deposit Service
- **Port**: 3004
- **Health Check**: `http://localhost:3004/health`
- **Endpoints**:
  - `POST /api/deposits` - Create deposit payment intent
  - `GET /api/deposits/:paymentIntentId` - Get deposit status
- Integrates with Stripe for payment processing

### Front-end
- **Port**: 3003 (default)
- **URL**: `http://localhost:3003`
- Next.js application with pages for:
  - Login/Registration
  - User Profile
  - Roulette game
  - Deposit functionality

## Environment Variables

Each service requires specific environment variables. See individual service README files for details:

- [API Gateway README](./api-gateway/README.md)
- [Auth Service README](./auth-service/README.md)
- [User Service README](./user-service/README.md)
- [Deposit Service README](./deposit-service/README.md)
- [Front-end README](./front-end/README.md)

## Development

### Running Services Locally

Each service can be run independently:

```bash
# Install dependencies
cd <service-directory>
npm install

# Run in development mode
npm run dev

# Build for production
npm run build

# Start production build
npm start
```

### Database Setup

#### User Service Database
```bash
cd user-service
npm run prisma:generate
npm run prisma:migrate
```

#### Auth Service Database
```bash
cd auth-service
npm run prisma:generate
npm run prisma:migrate
```

## Scripts

### start-all.sh

The main startup script supports several commands:

```bash
./start-all.sh start    # Start all services (default)
./start-all.sh stop     # Stop all local services and port-forwards
./start-all.sh status   # Show status of all services
./start-all.sh logs <service-name>  # View logs for a service
./start-all.sh restart  # Stop and restart all services
```

## Project Structure

```
microservices1/
├── api-gateway/          # API Gateway service
├── auth-service/         # Authentication service
├── deposit-service/      # Payment processing service
├── user-service/         # User management service
├── front-end/            # Next.js frontend application
├── shared/               # Shared utilities and middleware
└── start-all.sh          # Main startup script
```

## API Documentation

### Authentication Flow

1. **Register**: `POST /api/users/create` (via gateway) or `POST /auth/register`
2. **Login**: `POST /auth/login` - Returns JWT access token and refresh token
3. **Use Token**: Include `Authorization: Bearer <token>` header in subsequent requests

### User Management

- All user operations go through the API Gateway at `/api/users/*`
- The gateway proxies requests to the User Service

### Deposit Flow

1. Create deposit: `POST /api/deposits` with amount and user ID
2. Returns Stripe PaymentIntent with client secret
3. Frontend uses Stripe.js to complete payment
4. Check status: `GET /api/deposits/:paymentIntentId`

## Troubleshooting

### Services Not Starting

1. Check Kubernetes cluster: `kubectl cluster-info`
2. Verify namespace exists: `kubectl get namespace microservices`
3. Check service logs: `kubectl logs -n microservices deployment/<service-name>`

### Port Conflicts

If ports are already in use, the `start-all.sh` script will attempt to find alternative ports for the front-end.

### Database Connection Issues

- Verify database is running
- Check `DATABASE_URL` environment variable
- Ensure database migrations have been run

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## License

ISC
