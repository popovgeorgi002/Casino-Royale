import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { logger } from './config/logger.js';
import userRoutes from './routes/user.routes.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

const isDevelopment = process.env.NODE_ENV !== 'production';
const corsOptions = {
  origin: isDevelopment
    ? true
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

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'user-service' });
});

app.use('/api/users', userRoutes);

app.listen(PORT, () => {
  logger.info(`User service running on port ${PORT}`);
});
