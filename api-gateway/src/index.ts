import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import gatewayRoutes from './routes/gateway.routes.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

// CORS configuration
const isDevelopment = process.env.NODE_ENV !== 'production';
const corsOptions = {
  origin: isDevelopment
    ? true // Allow all origins in development
    : [
        'http://localhost:3000',
        'http://localhost:3003',
        'http://localhost:3004',
        process.env.FRONTEND_URL || 'http://localhost:3003'
      ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

// Middleware
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'api-gateway' });
});

// Gateway routes
app.use('/gateway', gatewayRoutes);

// Proxy user-service routes through gateway
app.use('/api', gatewayRoutes);

// Start server
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

export default app;
