import Stripe from 'stripe';
import { logger } from '../config/logger.js';

export class StripeService {
  private stripe: Stripe;
  private publishableKey: string;

  constructor() {
    const secretKey = process.env.STRIPE_SECRET_KEY;
    this.publishableKey = process.env.STRIPE_PUBLISHABLE_KEY || '';

    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not defined in environment variables');
    }

    // Initialize Stripe with test mode (virtual money)
    // Using latest API version - Stripe will use the default if not specified
    this.stripe = new Stripe(secretKey);

    logger.info('Stripe service initialized (test mode)');
  }

  /**
   * Create a PaymentIntent for a deposit
   * This simulates a payment using Stripe's test mode
   */
  async createPaymentIntent(amount: number, currency: string = 'usd', metadata?: Record<string, string>): Promise<Stripe.PaymentIntent> {
    try {
      // In test mode, create payment intent without confirmation
      // We'll proceed with the deposit since we're using virtual money
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount, // Amount in cents
        currency,
        metadata: metadata || {},
      });

      logger.info(`PaymentIntent created (test mode): ${paymentIntent.id} for amount ${amount} ${currency}`);
      // In test mode, we treat the payment as successful even if status is not 'succeeded'
      return paymentIntent;
    } catch (error) {
      logger.error('Error creating PaymentIntent:', error);
      throw new Error(`Failed to create payment intent: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Confirm a PaymentIntent (simulate successful payment in test mode)
   * In test mode, we can auto-confirm with test card
   */
  async confirmPaymentIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
    try {
      const paymentIntent = await this.stripe.paymentIntents.confirm(paymentIntentId, {
        payment_method: 'pm_card_visa', // Test card for auto-confirmation
      });

      logger.info(`PaymentIntent confirmed: ${paymentIntentId}`);
      return paymentIntent;
    } catch (error) {
      logger.error('Error confirming PaymentIntent:', error);
      throw new Error(`Failed to confirm payment intent: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Retrieve a PaymentIntent
   */
  async getPaymentIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
    try {
      const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentIntentId);
      return paymentIntent;
    } catch (error) {
      logger.error('Error retrieving PaymentIntent:', error);
      throw new Error(`Failed to retrieve payment intent: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Get publishable key for frontend
   */
  getPublishableKey(): string {
    return this.publishableKey;
  }
}
