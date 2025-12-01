import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import gatewayRoutes from './routes/gateway.routes.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
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
