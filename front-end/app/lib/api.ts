import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
const GATEWAY_URL = process.env.NEXT_PUBLIC_GATEWAY_URL || 'http://localhost:3002';

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  success: boolean;
  data: {
    accessToken: string;
    refreshToken: string;
  };
  message?: string;
}

export const authApi = {
  async login(data: LoginRequest): Promise<AuthResponse> {
    const response = await axios.post(`${API_BASE_URL}/auth/login`, data);
    return response.data;
  },

  async register(data: RegisterRequest): Promise<AuthResponse> {
    const response = await axios.post(`${API_BASE_URL}/auth/register`, data);
    return response.data;
  },
};

export interface DepositRequest {
  userId: string;
  amount: number; // Amount in cents
  currency?: string;
}

export interface DepositResponse {
  success: boolean;
  data?: {
    depositId: string;
    userId: string;
    amount: number;
    currency: string;
    status: string;
    paymentIntentId?: string;
    updatedBalance?: number;
  };
  error?: string;
}

export interface UserResponse {
  success: boolean;
  data?: {
    id: string;
    balance: number;
  };
  error?: string;
}

export interface UpdateBalanceRequest {
  balance: number;
}

export const userApi = {
  async getUserById(userId: string, token: string): Promise<UserResponse> {
    const response = await axios.get(`${GATEWAY_URL}/gateway/users/${userId}`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    return response.data;
  },

  async updateBalance(userId: string, balance: number, token: string): Promise<UserResponse> {
    try {
      console.log(`[API] Updating balance: userId=${userId}, balance=${balance}, url=${GATEWAY_URL}/gateway/users/${userId}`);
      const response = await axios.put(
        `${GATEWAY_URL}/gateway/users/${userId}`,
        { balance },
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );
      console.log('[API] Update balance response:', response.data);
      return response.data;
    } catch (error: any) {
      console.error('[API] Update balance error:', error);
      console.error('[API] Error response:', error.response?.data);
      console.error('[API] Error status:', error.response?.status);
      throw error;
    }
  },
};

export const depositApi = {
  async createDeposit(data: DepositRequest, token: string): Promise<DepositResponse> {
    const response = await axios.post(`${GATEWAY_URL}/api/deposits`, data, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });
    return response.data;
  },
};
