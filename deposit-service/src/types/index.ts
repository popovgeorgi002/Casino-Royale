export interface CreateDepositRequest {
  userId: string;
  amount: number;
  currency?: string;
}

export interface DepositResponse {
  success: boolean;
  data?: {
    depositId: string;
    userId: string;
    amount: number;
    currency: string;
    status: 'pending' | 'succeeded' | 'failed';
    paymentIntentId?: string;
    updatedBalance?: number;
  };
  error?: string;
}

export interface StripePaymentIntent {
  id: string;
  amount: number;
  currency: string;
  status: string;
  client_secret: string;
}
