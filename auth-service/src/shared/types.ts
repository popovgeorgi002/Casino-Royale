// Type definitions
export type JWTPayload = {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
};

export type AuthTokens = {
  accessToken: string;
  refreshToken: string;
};

// Class that can be instantiated at runtime
export class ServiceError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
    public originalError?: unknown
  ) {
    super(message);
    this.name = 'ServiceError';
    Object.setPrototypeOf(this, ServiceError.prototype);
  }
}
