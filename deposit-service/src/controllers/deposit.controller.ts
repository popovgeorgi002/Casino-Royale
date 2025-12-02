import type { Request, Response } from 'express';
import { DepositService } from '../services/deposit.service.js';
import { logger } from '../config/logger.js';
import type { CreateDepositRequest } from '../types/index.js';

export class DepositController {
  private depositService: DepositService;

  constructor() {
    this.depositService = new DepositService();
  }

  /**
   * Create and process a deposit
   * POST /api/deposits
   */
  async createDeposit(req: Request, res: Response): Promise<void> {
    try {
      const { userId, amount, currency } = req.body as CreateDepositRequest;

      // Validate input
      if (!userId) {
        res.status(400).json({
          success: false,
          error: 'User ID is required',
        });
        return;
      }

      if (!amount || amount <= 0) {
        res.status(400).json({
          success: false,
          error: 'Amount must be greater than 0',
        });
        return;
      }

      // Amount should be in cents (minimum $0.50 = 50 cents)
      if (amount < 50) {
        res.status(400).json({
          success: false,
          error: 'Minimum deposit amount is $0.50 (50 cents)',
        });
        return;
      }

      logger.info(`Creating deposit: userId=${userId}, amount=${amount}`);

      const result = await this.depositService.processDeposit({
        userId,
        amount,
        currency: currency || 'usd',
      });

      if (result.success) {
        res.status(201).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      logger.error('Error in createDeposit:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error',
      });
    }
  }

  /**
   * Get deposit status
   * GET /api/deposits/:paymentIntentId
   */
  async getDepositStatus(req: Request, res: Response): Promise<void> {
    try {
      const { paymentIntentId } = req.params;

      if (!paymentIntentId) {
        res.status(400).json({
          success: false,
          error: 'Payment Intent ID is required',
        });
        return;
      }

      const result = await this.depositService.getDepositStatus(paymentIntentId);

      if (result.success) {
        res.status(200).json(result);
      } else {
        res.status(404).json(result);
      }
    } catch (error) {
      logger.error('Error in getDepositStatus:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error',
      });
    }
  }
}
