import axios from 'axios';

export class GatewayService {
  private gatewayUrl: string;

  constructor() {
    this.gatewayUrl = process.env.API_GATEWAY_URL || 'http://api-gateway:3002';
  }

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
          timeout: 10000,
        }
      );
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const message = error.response?.data?.error || error.message || 'Failed to create user in user-service';
        console.error(`Gateway service error: ${message}`);
      } else {
        console.error('Unexpected error calling gateway:', error);
      }
    }
  }
}
