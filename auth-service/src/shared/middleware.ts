import type { Request, Response } from 'express';
import Joi from 'joi';
import { ServiceError } from './types.js';

// Define NextFunction type for Express 5 compatibility
type NextFunction = (err?: any) => void;

export function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>
) {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

export function validateRequest(schema: Joi.ObjectSchema) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errorMessages = error.details.map((detail) => detail.message).join(', ');
      res.status(400).json({
        success: false,
        error: errorMessages,
      });
      return;
    }

    req.body = value;
    next();
  };
}

export function authenticateToken(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    res.status(401).json({
      success: false,
      error: 'Access token is required',
    });
    return;
  }

  // Token validation will be handled by the service layer
  // This middleware just extracts the token
  (req as any).token = token;
  next();
}
