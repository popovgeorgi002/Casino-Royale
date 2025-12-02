import axios from 'axios';

export class UserService {
  private userServiceUrl: string;

  constructor() {
    this.userServiceUrl = process.env.USER_SERVICE_URL || 'http://user-service:3000';
  }

  /**
   * Get user by ID from user-service
   */
  async getUserById(userId: string) {
    try {
      const response = await axios.get(
        `${this.userServiceUrl}/api/users/${userId}`,
        {
          timeout: 10000,
        }
      );

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const message = error.response?.data?.error || error.message || 'Failed to get user';
        const statusCode = error.response?.status || 500;
        throw new Error(`User service error (${statusCode}): ${message}`);
      }
      throw error;
    }
  }

  /**
   * Update user balance in user-service
   */
  async updateUserBalance(userId: string, newBalance: number) {
    try {
      const response = await axios.put(
        `${this.userServiceUrl}/api/users/${userId}`,
        {
          balance: newBalance,
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        }
      );

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const message = error.response?.data?.error || error.message || 'Failed to update user balance';
        const statusCode = error.response?.status || 500;
        throw new Error(`User service error (${statusCode}): ${message}`);
      }
      throw error;
    }
  }
}
