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
          timeout: 10000,
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
