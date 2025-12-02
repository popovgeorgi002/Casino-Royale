import { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';

// Extend Express Request to include correlationId
declare global {
  namespace Express {
    interface Request {
      correlationId?: string;
    }
  }
}

/**
 * Middleware to add correlation ID to requests
 * This helps trace requests across multiple microservices
 */
export const correlationIdMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  // Get correlation ID from header or generate new one
  const correlationId = 
    (req.headers['x-correlation-id'] as string) || 
    randomUUID();

  // Add to request object for use in controllers/services
  req.correlationId = correlationId;

  // Add to response header so clients can track requests
  res.setHeader('X-Correlation-ID', correlationId);

  next();
};
