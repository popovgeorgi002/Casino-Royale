import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import gatewayRoutes from './routes/gateway.routes.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

const isDevelopment = process.env.NODE_ENV !== 'production';
const corsOptions = {
  origin: isDevelopment
    ? true
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

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'api-gateway' });
});

app.use('/gateway', gatewayRoutes);

app.use('/api', gatewayRoutes);

app.use((req, res, next) => {
  if (req.method === 'PUT' && req.path.includes('/users/')) {
    console.log(`[GATEWAY] ${req.method} ${req.path} - Original URL: ${req.originalUrl}`);
  }
  next();
});

app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

export default app;
