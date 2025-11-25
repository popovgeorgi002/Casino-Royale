import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { logger } from './config/logger';
import userRoutes from './routes/user.routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'user-service' });
});

// Routes
app.use('/api/users', userRoutes);

// Start server
app.listen(PORT, () => {
  logger.info(`User service running on port ${PORT}`);
});
