export interface CreateDepositRequest {
  userId: string;
  amount: number; // Amount in cents (e.g., 1000 = $10.00)
  currency?: string; // Default: 'usd'
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
