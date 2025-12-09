import { Request, Response, NextFunction } from 'express';

export const requestLogger = (
  logger: { info: (message: string, meta?: any) => void }
) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();

    logger.info('Incoming request', {
      correlationId: req.correlationId,
      method: req.method,
      path: req.path,
      ip: req.ip,
      userAgent: req.get('user-agent'),
    });

    res.on('finish', () => {
      const duration = Date.now() - start;
      logger.info('Request completed', {
        correlationId: req.correlationId,
        method: req.method,
        path: req.path,
        statusCode: res.statusCode,
        duration: `${duration}ms`,
      });
    });

    next();
  };
};
