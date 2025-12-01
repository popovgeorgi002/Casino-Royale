import { ServiceError } from './types.js';

export function createServiceError(
  message: string,
  statusCode: number = 500,
  originalError?: unknown
): ServiceError {
  return new ServiceError(message, statusCode, originalError);
}

export function createSuccessResponse<T>(
  data: T,
  message: string = 'Success'
): { success: true; data: T; message: string } {
  return {
    success: true,
    data,
    message,
  };
}

export function createErrorResponse(
  message: string,
  statusCode: number = 500
): { success: false; error: string; statusCode: number } {
  return {
    success: false,
    error: message,
    statusCode,
  };
}
