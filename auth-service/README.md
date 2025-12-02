# Auth Service

Authentication and authorization service that handles user registration, login, and JWT token management.

## Overview

The Auth Service provides:
- User registration with password hashing
- User login with JWT token generation
- JWT access token and refresh token management
- Token validation middleware
- Secure password storage using bcrypt

## Port

- **Default**: 3001
- **Configurable**: Set `PORT` environment variable

## Environment Variables

```bash
PORT=3001                                    # Server port
NODE_ENV=development                         # Environment (development/production)
DATABASE_URL=postgresql://user:pass@host:5432/dbname  # PostgreSQL connection string
JWT_SECRET=your-secret-key                   # Secret for JWT access tokens
JWT_REFRESH_SECRET=your-refresh-secret      # Secret for JWT refresh tokens
JWT_EXPIRES_IN=15m                          # Access token expiration time
JWT_REFRESH_EXPIRES_IN=7d                   # Refresh token expiration time
BCRYPT_ROUNDS=10                             # Bcrypt salt rounds
API_GATEWAY_URL=http://api-gateway:3002     # API Gateway URL (optional)
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

### Database Schema

The service uses PostgreSQL with the following models:

- **User**: Stores user credentials (email, hashed password)
- **RefreshToken**: Stores refresh tokens for token rotation

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
- `GET /test` - Test endpoint for debugging

### Authentication
- `POST /auth/register` - Register a new user
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword"
  }
  ```

- `POST /auth/login` - Login and receive JWT tokens
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword"
  }
  ```
  
  Response:
  ```json
  {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid",
      "email": "user@example.com"
    }
  }
  ```

## Architecture

```
auth-service/
├── src/
│   ├── authController.ts      # Request handlers
│   ├── authService.ts         # Business logic
│   ├── database.ts            # Prisma client setup
│   ├── routes.ts              # Route definitions
│   ├── index.ts               # Application entry point
│   ├── shared/
│   │   ├── middleware.ts      # Authentication middleware
│   │   ├── types.ts           # TypeScript types
│   │   ├── utils.ts           # Utility functions
│   │   └── validation.ts      # Request validation schemas
│   └── services/
│       └── gateway.service.ts # Gateway communication
├── prisma/
│   ├── schema.prisma          # Database schema
│   └── migrations/            # Database migrations
├── k8s/                       # Kubernetes deployment files
└── Dockerfile                 # Docker image definition
```

## Security Features

1. **Password Hashing**: Uses bcrypt with configurable salt rounds
2. **JWT Tokens**: Secure token-based authentication
3. **Token Expiration**: Short-lived access tokens (15m) and longer refresh tokens (7d)
4. **Input Validation**: Joi schema validation for all inputs
5. **Helmet**: Security headers middleware
6. **CORS**: Configurable CORS policy

## Middleware

### Authentication Middleware

The `authenticateToken` middleware validates JWT access tokens:

```typescript
import { authenticateToken } from './shared/middleware';

router.get('/protected', authenticateToken, (req, res) => {
  // req.user contains decoded token payload
});
```

### Validation Middleware

The `validateRequest` middleware validates request bodies:

```typescript
import { validateRequest } from './shared/middleware';
import { loginSchema } from './validation';

router.post('/login', validateRequest(loginSchema), handler);
```

## Database Models

### User Model
```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  password  String
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  refreshTokens RefreshToken[]
}
```

### RefreshToken Model
```prisma
model RefreshToken {
  id        String   @id @default(uuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())
  user      User     @relation(...)
}
```

## Kubernetes Deployment

The service includes Kubernetes deployment files in `k8s/`:

- `deployment.yaml` - Deployment configuration
- `service.yaml` - Service definition
- `configmap.yaml` - Configuration map
- `secret.yaml` - Secrets (database URL, JWT secrets)

To deploy:

```bash
kubectl apply -f k8s/
```

**Important**: Update `k8s/secret.yaml` with your actual secrets before deploying.

## Docker

Build the Docker image:

```bash
docker build -t auth-service:latest .
```

## Dependencies

- **express** - Web framework
- **@prisma/client** - Prisma ORM client
- **prisma** - Prisma CLI and tools
- **bcryptjs** - Password hashing
- **jsonwebtoken** - JWT token generation and validation
- **joi** - Input validation
- **helmet** - Security headers
- **cors** - CORS middleware
- **dotenv** - Environment variable management
- **axios** - HTTP client for gateway communication

## Error Handling

The service returns appropriate HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid credentials)
- `409` - Conflict (email already exists)
- `500` - Internal Server Error

## Health Check

The `/health` endpoint returns:
```json
{
  "status": "ok",
  "service": "auth-service"
}
```

Use this endpoint for Kubernetes liveness and readiness probes.

## Testing

Example registration request:

```bash
curl -X POST http://localhost:3001/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Example login request:

```bash
curl -X POST http://localhost:3001/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```
