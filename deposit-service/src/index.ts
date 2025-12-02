import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { logger } from './config/logger.js';
import depositRoutes from './routes/deposit.routes.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3004;

// CORS configuration
const isDevelopment = process.env.NODE_ENV !== 'production';
const corsOptions = {
  origin: isDevelopment
    ? true // Allow all origins in development
    : [
        'http://localhost:3000',
        'http://localhost:3002',
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
  res.status(200).json({ status: 'ok', service: 'deposit-service' });
});

// Routes
app.use('/api/deposits', depositRoutes);

// Start server
app.listen(PORT, () => {
  logger.info(`Deposit service running on port ${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`Health check: http://localhost:${PORT}/health`);
});
