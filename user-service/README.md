# User Service

User management service that handles user profiles, balances, and CRUD operations.

## Overview

The User Service provides:
- User creation and management
- User balance tracking
- User profile operations (CRUD)
- Integration with other services for user data

## Port

- **Default**: 3000
- **Configurable**: Set `PORT` environment variable

## Environment Variables

```bash
PORT=3000                                    # Server port
NODE_ENV=development                         # Environment (development/production)
DATABASE_URL=postgresql://user:pass@host:5432/dbname  # PostgreSQL connection string
JWT_SECRET=your-secret-key                   # JWT secret for token validation
```

## Installation

```bash
npm install
```

## Database Setup

### Prisma Setup

1. **Generate Prisma Client:**
```bash
npm run prisma:generate
```

2. **Run Migrations:**
```bash
npm run prisma:migrate
```

3. **Open Prisma Studio (optional):**
```bash
npm run prisma:studio
```

### Local Database with Docker Compose

A `docker-compose.db.yml` file is provided for local development:

```bash
docker-compose -f docker-compose.db.yml up -d
```

This starts a PostgreSQL database on port 5432.

### Database Schema

The service uses PostgreSQL with the following model:

- **User**: Stores user information (id, balance)

```prisma
model User {
  id      String @id @default(uuid())
  balance Int    @default(0)
}
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

### User Operations
- `GET /api/users/:id` - Get user by ID
  ```json
  {
    "id": "uuid",
    "balance": 1000
  }
  ```

- `POST /api/users` - Create a new user
  ```json
  {
    "id": "uuid",        // Optional, will be generated if not provided
    "balance": 0         // Optional, defaults to 0
  }
  ```

- `PUT /api/users/:id` - Update user
  ```json
  {
    "balance": 5000      // Update balance
  }
  ```

- `DELETE /api/users/:id` - Delete user

## Architecture

```
user-service/
├── src/
│   ├── config/
│   │   ├── database.ts         # Prisma client setup
│   │   └── logger.ts           # Winston logger configuration
│   ├── controllers/
│   │   └── user.controller.ts  # Request handlers
│   ├── routes/
│   │   └── user.routes.ts      # Route definitions
│   ├── services/
│   │   └── user.service.ts     # Business logic
│   ├── types/
│   │   └── index.ts            # TypeScript types
│   └── index.ts                # Application entry point
├── prisma/
│   ├── schema.prisma           # Database schema
│   └── migrations/            # Database migrations
├── k8s/                       # Kubernetes deployment files
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── migration-job.yaml     # Database migration job
│   ├── namespace.yaml
│   └── postgres-deployment.yaml  # PostgreSQL deployment
└── Dockerfile                 # Docker image definition
```

## Features

### User Balance Management

The service tracks user balances as integers (representing cents or smallest currency unit). Balance updates are atomic operations.

### JWT Authentication

The service can validate JWT tokens (if `JWT_SECRET` is provided) for protected endpoints. Currently, endpoints are accessible without authentication, but the infrastructure is in place.

## Logging

The service uses Winston for structured logging:

- **Info**: General operations and successful requests
- **Error**: Database errors and service failures
- **Warn**: Warnings and validation issues

Logs are output to console and can be configured for file output.

## Kubernetes Deployment

The service includes comprehensive Kubernetes deployment files in `k8s/`:

- `namespace.yaml` - Namespace definition
- `postgres-deployment.yaml` - PostgreSQL database deployment
- `deployment.yaml` - User service deployment
- `service.yaml` - Service definition
- `configmap.yaml` - Configuration map
- `secret.yaml` - Secrets (database URL, JWT secret)
- `migration-job.yaml` - Database migration job

To deploy:

```bash
kubectl apply -f k8s/
```

**Important**: 
- Update `k8s/secret.yaml` with your actual secrets before deploying
- Run migrations: `kubectl apply -f k8s/migration-job.yaml`

## Docker

Build the Docker image:

```bash
docker build -t user-service:latest .
```

## Dependencies

- **express** - Web framework
- **@prisma/client** - Prisma ORM client
- **prisma** - Prisma CLI and tools
- **jsonwebtoken** - JWT token validation
- **express-validator** - Request validation
- **winston** - Logging library
- **bcryptjs** - Password hashing utilities
- **cors** - CORS middleware
- **dotenv** - Environment variable management
- **typescript** - TypeScript support
- **tsx** - TypeScript execution for development

## Error Handling

The service returns appropriate HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `404` - Not Found (user not found)
- `500` - Internal Server Error (database errors)

## Health Check

The `/health` endpoint returns:
```json
{
  "status": "ok",
  "service": "user-service"
}
```

Use this endpoint for Kubernetes liveness and readiness probes.

## Testing

Example create user:

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "balance": 1000
  }'
```

Example get user:

```bash
curl http://localhost:3000/api/users/{user-id}
```

Example update user:

```bash
curl -X PUT http://localhost:3000/api/users/{user-id} \
  -H "Content-Type: application/json" \
  -d '{
    "balance": 5000
  }'
```

Example delete user:

```bash
curl -X DELETE http://localhost:3000/api/users/{user-id}
```

## Database Migrations

Migrations are managed through Prisma:

```bash
# Create a new migration
npm run prisma:migrate

# Apply migrations in production
npx prisma migrate deploy
```

The Kubernetes deployment includes a migration job that runs before the service starts.

## Integration with Other Services

The user service is typically accessed through the API Gateway, which handles:
- Request routing
- Load balancing
- Service discovery

Direct access is also possible for internal service-to-service communication.
