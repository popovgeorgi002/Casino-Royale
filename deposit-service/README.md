# Deposit Service

Microservice for handling deposits using Stripe API (test mode with virtual money).

## Features

- Stripe Payment Intent integration (test mode)
- Automatic user balance updates in user-service
- Deposit status tracking
- Health check endpoint

## Environment Variables

```env
PORT=3004
NODE_ENV=development
STRIPE_SECRET_KEY=sk_test_your_stripe_test_secret_key
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_test_publishable_key
USER_SERVICE_URL=http://user-service:3000
API_GATEWAY_URL=http://api-gateway:3002
```

## API Endpoints

### Create Deposit
```
POST /api/deposits
Content-Type: application/json

{
  "userId": "user-id-here",
  "amount": 1000,  // Amount in cents (1000 = $10.00)
  "currency": "usd"  // Optional, defaults to "usd"
}
```

### Get Deposit Status
```
GET /api/deposits/:paymentIntentId
```

### Health Check
```
GET /health
```

## Stripe Test Mode

This service uses Stripe's test mode, which allows you to:
- Use test API keys (start with `sk_test_` and `pk_test_`)
- Process payments without real money
- Use test card numbers for testing

### Test Card Numbers
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- Requires authentication: `4000 0025 0000 3155`

## Flow

1. Client sends deposit request to API Gateway
2. API Gateway forwards to Deposit Service
3. Deposit Service creates Stripe PaymentIntent
4. PaymentIntent is confirmed (auto-confirmed in test mode)
5. User balance is updated in user-service
6. Response returned with deposit details

## Building and Deploying

```bash
# Build Docker image
docker build -t deposit-service:latest .

# Load into Kubernetes (if using kind)
kind load docker-image deposit-service:latest --name microservices

# Apply Kubernetes resources
kubectl apply -f k8s/
```

## Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Build
npm run build

# Start production
npm start
```
