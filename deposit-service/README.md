# Deposit Service

Payment processing service that handles deposits using Stripe integration.

## Overview

The Deposit Service provides:
- Stripe PaymentIntent creation
- Payment status tracking
- Integration with User Service for balance updates
- Secure payment processing using Stripe API

## Port

- **Default**: 3004
- **Configurable**: Set `PORT` environment variable

## Environment Variables

```bash
PORT=3004                                    # Server port
NODE_ENV=development                         # Environment (development/production)
STRIPE_SECRET_KEY=sk_test_...                # Stripe secret key
STRIPE_PUBLISHABLE_KEY=pk_test_...           # Stripe publishable key
USER_SERVICE_URL=http://user-service:3000    # User service URL
API_GATEWAY_URL=http://api-gateway:3002     # API Gateway URL (optional)
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

### Deposit Operations
- `POST /api/deposits` - Create a deposit payment intent
  ```json
  {
    "amount": 10000,        // Amount in cents (e.g., 10000 = $100.00)
    "currency": "usd",      // Currency code
    "userId": "user-uuid"   // User ID
  }
  ```
  
  Response:
  ```json
  {
    "paymentIntentId": "pi_...",
    "clientSecret": "pi_..._secret_...",
    "amount": 10000,
    "currency": "usd",
    "status": "requires_payment_method"
  }
  ```

- `GET /api/deposits/:paymentIntentId` - Get deposit status
  ```json
  {
    "paymentIntentId": "pi_...",
    "status": "succeeded",
    "amount": 10000,
    "currency": "usd",
    "metadata": {
      "userId": "user-uuid"
    }
  }
  ```

## Architecture

```
deposit-service/
├── src/
│   ├── config/
│   │   └── logger.ts           # Winston logger configuration
│   ├── controllers/
│   │   └── deposit.controller.ts  # Request handlers
│   ├── routes/
│   │   └── deposit.routes.ts    # Route definitions
│   ├── services/
│   │   ├── deposit.service.ts  # Business logic
│   │   ├── stripe.service.ts   # Stripe API integration
│   │   └── user.service.ts     # User service client
│   ├── types/
│   │   └── index.ts            # TypeScript types
│   └── index.ts                # Application entry point
├── k8s/                        # Kubernetes deployment files
└── Dockerfile                  # Docker image definition
```

## Stripe Integration

The service uses Stripe's PaymentIntent API for payment processing:

1. **Create PaymentIntent**: Creates a payment intent with the specified amount
2. **Confirm Payment**: Frontend uses Stripe.js to confirm payment with client secret
3. **Status Check**: Service can retrieve payment status at any time

### Test Mode

The service is configured for Stripe test mode. Use test card numbers:
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`

## Payment Flow

1. Client requests deposit creation via API Gateway
2. Service creates Stripe PaymentIntent
3. Returns client secret to frontend
4. Frontend uses Stripe.js to complete payment
5. Stripe webhook (optional) or polling confirms payment
6. Service updates user balance in User Service

## Logging

The service uses Winston for structured logging:

- **Info**: General operations and successful payments
- **Error**: Payment failures and service errors
- **Warn**: Warnings and retries

Logs are output to console and can be configured for file output.

## Service Communication

### User Service Integration

The deposit service communicates with the user service to:
- Verify user existence
- Update user balance after successful payment

## Kubernetes Deployment

The service includes Kubernetes deployment files in `k8s/`:

- `deployment.yaml` - Deployment configuration
- `service.yaml` - Service definition
- `secret.yaml` - Stripe API keys

To deploy:

```bash
kubectl apply -f k8s/
```

**Important**: Update `k8s/secret.yaml` with your Stripe API keys before deploying.

## Docker

Build the Docker image:

```bash
docker build -t deposit-service:latest .
```

## Dependencies

- **express** - Web framework
- **stripe** - Stripe SDK for payment processing
- **axios** - HTTP client for service communication
- **winston** - Logging library
- **cors** - CORS middleware
- **dotenv** - Environment variable management
- **typescript** - TypeScript support
- **tsx** - TypeScript execution for development

## Error Handling

The service returns appropriate HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (invalid amount, missing fields)
- `404` - Not Found (payment intent not found)
- `500` - Internal Server Error (Stripe API errors, service errors)

## Health Check

The `/health` endpoint returns:
```json
{
  "status": "ok",
  "service": "deposit-service"
}
```

Use this endpoint for Kubernetes liveness and readiness probes.

## Testing

Example deposit creation:

```bash
curl -X POST http://localhost:3004/api/deposits \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 10000,
    "currency": "usd",
    "userId": "user-uuid-here"
  }'
```

Example status check:

```bash
curl http://localhost:3004/api/deposits/pi_xxxxx
```

## Stripe Setup

1. Create a Stripe account at https://stripe.com
2. Get your API keys from the Stripe Dashboard
3. Use test keys for development (start with `sk_test_` and `pk_test_`)
4. Set environment variables or update Kubernetes secrets

## Security Considerations

- Never expose Stripe secret keys in client-side code
- Use HTTPS in production
- Validate amounts server-side
- Implement rate limiting for deposit endpoints
- Monitor for suspicious payment patterns
