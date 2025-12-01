# Microservices Casino Platform

A full-stack microservices application with a casino frontend.

## Architecture

- **User Service** (Port 3000) - User management service
- **Auth Service** (Port 3001) - Authentication and authorization
- **API Gateway** (Port 3002) - Gateway for routing requests
- **Front-end** (Port 3000/3003) - Next.js casino application

## Quick Start

### Start All Services

Use the provided startup script:

```bash
./start-all.sh
```

Or with specific commands:

```bash
# Start all services
./start-all.sh start

# Stop all services
./start-all.sh stop

# Check status
./start-all.sh status

# View logs
./start-all.sh logs <service-name>

# Restart all services
./start-all.sh restart
```

### Manual Start

If you prefer to start services manually:

#### 1. User Service
```bash
cd user-service
npm install
npm run dev
```

#### 2. Auth Service
```bash
cd auth-service
npm install
npm run dev
```

#### 3. API Gateway
```bash
cd api-gateway
npm install
npm run dev
```

#### 4. Front-end
```bash
cd front-end
npm install
npm run dev
```

## Environment Variables

### User Service
Create `user-service/.env`:
```
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://user:password@localhost:5432/userdb
JWT_SECRET=your-secret-key
```

### Auth Service
Create `auth-service/.env`:
```
PORT=3001
NODE_ENV=development
DATABASE_URL=postgresql://user:password@localhost:5432/authdb
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret-key
API_GATEWAY_URL=http://localhost:3002
```

### API Gateway
Create `api-gateway/.env`:
```
PORT=3002
NODE_ENV=development
USER_SERVICE_URL=http://localhost:3000
AUTH_SERVICE_URL=http://localhost:3001
```

### Front-end
Create `front-end/.env.local`:
```
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_GATEWAY_URL=http://localhost:3002
```

## Service URLs

- **User Service**: http://localhost:3000
- **Auth Service**: http://localhost:3001
- **API Gateway**: http://localhost:3002
- **Front-end**: http://localhost:3000 (or 3003 if 3000 is in use)

## Database Setup

### User Service Database
```bash
cd user-service
npm run prisma:generate
npm run prisma:migrate
```

### Auth Service Database
```bash
cd auth-service
npm run prisma:generate
npm run prisma:migrate
```

## Kubernetes Deployment

To deploy to Kubernetes (kind):

```bash
# Build and load images
docker build -t user-service:latest ./user-service
docker build -t auth-service:latest ./auth-service
docker build -t api-gateway:latest ./api-gateway

kind load docker-image user-service:latest --name microservices
kind load docker-image auth-service:latest --name microservices
kind load docker-image api-gateway:latest --name microservices

# Apply Kubernetes configs
kubectl apply -f user-service/k8s/
kubectl apply -f auth-service/k8s/
kubectl apply -f api-gateway/k8s/
```

## Project Structure

```
microservices1/
├── user-service/      # User management service
├── auth-service/      # Authentication service
├── api-gateway/       # API Gateway
├── front-end/         # Next.js frontend
├── start-all.sh       # Startup script
└── README.md          # This file
```

## Development

### Prerequisites
- Node.js 20+ and npm
- PostgreSQL (for databases)
- Docker (optional, for Kubernetes)

### Installing Node.js and npm

If you don't have Node.js installed, you can use the helper script:

```bash
./install-node.sh
```

Or install manually:

**Using nvm (recommended):**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

**Using package manager:**
- Ubuntu/Debian: `sudo apt-get install nodejs npm`
- Fedora: `sudo dnf install nodejs npm`
- Arch: `sudo pacman -S nodejs npm`

**Note:** If you're using nvm, make sure to load it before running the startup script:
```bash
source ~/.nvm/nvm.sh
./start-all.sh
```

### Logs

Service logs are stored in the `logs/` directory:
- `logs/user-service.log`
- `logs/auth-service.log`
- `logs/api-gateway.log`
- `logs/front-end.log`

## Troubleshooting

### Port Already in Use
If a port is already in use, the script will warn you. You can:
1. Stop the service using that port
2. Change the port in the service's configuration
3. Use `./start-all.sh stop` to stop all services

### Services Not Starting
1. Check if dependencies are installed: `npm install` in each service directory
2. Check if databases are running and accessible
3. Verify environment variables are set correctly
4. Check logs: `./start-all.sh logs <service-name>`

## License

ISC
