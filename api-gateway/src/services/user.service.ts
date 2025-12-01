import axios from 'axios';
import { SERVICE_URLS } from '../config/services.js';

export interface CreateUserRequest {
  id: string;
  balance?: number;
}

export class UserService {
  private userServiceUrl: string;

  constructor() {
    this.userServiceUrl = SERVICE_URLS.USER_SERVICE;
  }

  /**
   * Create a user in the user-service
   * This method is called by auth-service after user registration
   * @param userData User data with ID from auth-service and balance
   * @returns Created user
   */
  async createUser(userData: CreateUserRequest) {
    try {
      const response = await axios.post(
        `${this.userServiceUrl}/api/users`,
        {
          id: userData.id,
          balance: userData.balance ?? 0,
        },
        {
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: 10000, // 10 second timeout
        }
      );

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const message = error.response?.data?.error || error.message || 'Failed to create user in user-service';
        const statusCode = error.response?.status || 500;
        throw new Error(`User service error (${statusCode}): ${message}`);
      }
      throw error;
    }
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
}
