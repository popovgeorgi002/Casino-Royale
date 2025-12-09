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

    this.stripe = new Stripe(secretKey);

    logger.info('Stripe service initialized (test mode)');
  }

  async createPaymentIntent(amount: number, currency: string = 'usd', metadata?: Record<string, string>): Promise<Stripe.PaymentIntent> {
    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount,
        currency,
        metadata: metadata || {},
      });

      logger.info(`PaymentIntent created (test mode): ${paymentIntent.id} for amount ${amount} ${currency}`);
      return paymentIntent;
    } catch (error) {
      logger.error('Error creating PaymentIntent:', error);
      throw new Error(`Failed to create payment intent: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async confirmPaymentIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
    try {
      const paymentIntent = await this.stripe.paymentIntents.confirm(paymentIntentId, {
        payment_method: 'pm_card_visa',
      });

      logger.info(`PaymentIntent confirmed: ${paymentIntentId}`);
      return paymentIntent;
    } catch (error) {
      logger.error('Error confirming PaymentIntent:', error);
      throw new Error(`Failed to confirm payment intent: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async getPaymentIntent(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
    try {
      const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentIntentId);
      return paymentIntent;
    } catch (error) {
      logger.error('Error retrieving PaymentIntent:', error);
      throw new Error(`Failed to retrieve payment intent: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  getPublishableKey(): string {
    return this.publishableKey;
  }
}
