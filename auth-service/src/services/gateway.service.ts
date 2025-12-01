import axios from 'axios';

export class GatewayService {
  private gatewayUrl: string;

  constructor() {
    this.gatewayUrl = process.env.API_GATEWAY_URL || 'http://api-gateway:3002';
  }

  /**
   * Create user in user-service via API Gateway
   * Called after successful user registration in auth-service
   * @param userId The user ID from auth database
   * @param balance Initial balance (defaults to 0)
   */
  async createUserInUserService(userId: string, balance: number = 0): Promise<void> {
    try {
      await axios.post(
        `${this.gatewayUrl}/gateway/users/create`,
        {
          id: userId,
          balance,
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: 10000, // 10 second timeout
        }
      );
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const message = error.response?.data?.error || error.message || 'Failed to create user in user-service';
        console.error(`Gateway service error: ${message}`);
        // Don't throw - we don't want to fail registration if user-service is down
        // Log the error for later retry
      } else {
        console.error('Unexpected error calling gateway:', error);
      }
    }
  }
}
