# API Gateway

The API Gateway serves as the central entry point for all client requests, routing them to the appropriate microservices.

## Overview

The API Gateway handles:
- Request routing to backend services
- CORS configuration
- Request/response proxying
- Service discovery and load balancing

## Port

- **Default**: 3002
- **Configurable**: Set `PORT` environment variable

## Environment Variables

```bash
PORT=3002                                    # Server port
NODE_ENV=development                         # Environment (development/production)
USER_SERVICE_URL=http://user-service:3000    # User service URL
AUTH_SERVICE_URL=http://auth-service:3001   # Auth service URL
DEPOSIT_SERVICE_URL=http://deposit-service:3004  # Deposit service URL
FRONTEND_URL=http://localhost:3003           # Frontend URL for CORS
```

## Installation

```bash
npm install
```

## Development

```bash
npm run dev
```

Starts the server with hot-reload using `tsx watch`.

## Build

```bash
npm run build
```

Compiles TypeScript to JavaScript in the `dist/` directory.

## Production

```bash
npm start
```

Runs the compiled JavaScript from `dist/`.

## API Endpoints

### Health Check
- `GET /health` - Service health status

### User Routes (via Gateway)
- `POST /api/users/create` - Create user (gateway-specific endpoint)
- `GET /api/users/:id` - Get user by ID
- `GET /api/users` - Get all users
- `POST /api/users` - Create user (proxied to user-service)
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Deposit Routes (via Gateway)
- `POST /api/deposits` - Create deposit payment intent
- `GET /api/deposits/:paymentIntentId` - Get deposit status

## Architecture

The gateway uses Express.js with the following structure:

```
api-gateway/
├── src/
│   ├── config/
│   │   └── services.ts          # Service URL configuration
│   ├── controllers/
│   │   └── gateway.controller.ts # Request handling logic
│   ├── routes/
│   │   └── gateway.routes.ts     # Route definitions
│   ├── services/
│   │   └── user.service.ts       # User service client
│   └── index.ts                  # Application entry point
├── k8s/                          # Kubernetes deployment files
└── Dockerfile                    # Docker image definition
```

## Service Communication

The gateway communicates with backend services using HTTP requests:

- **User Service**: Manages user CRUD operations
- **Auth Service**: Handles authentication (currently not proxied, accessed directly)
- **Deposit Service**: Processes payment deposits

## CORS Configuration

CORS is configured to allow requests from:
- Development: All origins (`origin: true`)
- Production: Specific allowed origins including frontend URL

## Kubernetes Deployment

The service includes Kubernetes deployment files in `k8s/`:

- `deployment.yaml` - Deployment configuration
- `service.yaml` - Service definition

To deploy:

```bash
kubectl apply -f k8s/
```

## Docker

Build the Docker image:

```bash
docker build -t api-gateway:latest .
```

## Dependencies

- **express** - Web framework
- **axios** - HTTP client for service communication
- **cors** - CORS middleware
- **dotenv** - Environment variable management
- **typescript** - TypeScript support
- **tsx** - TypeScript execution for development

## Logging

The gateway logs:
- Incoming requests
- Proxied requests to backend services
- Response status codes
- Error details

## Error Handling

The gateway handles errors from backend services and returns appropriate HTTP status codes to clients.

## Health Check

The `/health` endpoint returns:
```json
{
  "status": "ok",
  "service": "api-gateway"
}
```

Use this endpoint for Kubernetes liveness and readiness probes.
