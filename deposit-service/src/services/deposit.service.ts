import { StripeService } from './stripe.service.js';
import { UserService } from './user.service.js';
import { logger } from '../config/logger.js';
import type { CreateDepositRequest, DepositResponse } from '../types/index.js';

export class DepositService {
  private stripeService: StripeService;
  private userService: UserService;

  constructor() {
    this.stripeService = new StripeService();
    this.userService = new UserService();
  }

  async processDeposit(request: CreateDepositRequest): Promise<DepositResponse> {
    const { userId, amount, currency = 'usd' } = request;

    try {
      logger.info(`Processing deposit for user ${userId}, amount: ${amount} ${currency}`);
      const userResponse = await this.userService.getUserById(userId);
      
      if (!userResponse.success || !userResponse.data) {
        throw new Error('User not found');
      }

      const currentBalance = userResponse.data.balance || 0;

      const paymentIntent = await this.stripeService.createPaymentIntent(
        amount,
        currency,
        {
          userId,
          service: 'deposit-service',
        }
      );

      logger.info(`PaymentIntent created with status: ${paymentIntent.status}, proceeding with deposit in test mode`);

      const amountInDollars = amount / 100;
      const newBalance = currentBalance + amountInDollars;

      await this.userService.updateUserBalance(userId, newBalance);

      logger.info(`Deposit successful: User ${userId}, Amount: $${amountInDollars}, New Balance: $${newBalance}`);

      return {
        success: true,
        data: {
          depositId: paymentIntent.id,
          userId,
          amount,
          currency,
          status: 'succeeded',
          paymentIntentId: paymentIntent.id,
          updatedBalance: newBalance,
        },
      };
    } catch (error) {
      logger.error('Error processing deposit:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to process deposit',
      };
    }
  }

  async getDepositStatus(paymentIntentId: string): Promise<DepositResponse> {
    try {
      const paymentIntent = await this.stripeService.getPaymentIntent(paymentIntentId);
      
      return {
        success: true,
        data: {
          depositId: paymentIntent.id,
          userId: paymentIntent.metadata.userId || '',
          amount: paymentIntent.amount,
          currency: paymentIntent.currency,
          status: paymentIntent.status === 'succeeded' ? 'succeeded' : 
                 paymentIntent.status === 'processing' ? 'pending' : 'failed',
          paymentIntentId: paymentIntent.id,
        },
      };
    } catch (error) {
      logger.error('Error getting deposit status:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to get deposit status',
      };
    }
  }
}
