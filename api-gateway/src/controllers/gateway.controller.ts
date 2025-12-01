import type { Request, Response } from 'express';
import { UserService } from '../services/user.service.js';
import axios from 'axios';
import { SERVICE_URLS } from '../config/services.js';

export class GatewayController {
  private userService: UserService;

  constructor() {
    this.userService = new UserService();
  }

  /**
   * Create user in user-service
   * Called by auth-service after user registration
   * POST /gateway/users/create
   * Body: { id: string, balance?: number }
   */
  async createUser(req: Request, res: Response): Promise<void> {
    try {
      const { id, balance } = req.body;

      // Validate required fields
      if (!id) {
        res.status(400).json({
          success: false,
          error: 'Missing required field: id',
        });
        return;
      }

      // Create user in user-service with same ID and balance
      const result = await this.userService.createUser({
        id,
        balance: balance ?? 0,
      });

      res.status(201).json({
        success: true,
        data: result,
        message: 'User created in user-service successfully',
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to create user in user-service';
      res.status(500).json({
        success: false,
        error: message,
      });
    }
  }

  /**
   * Proxy GET requests to user-service
   * GET /api/users/:id
   */
  async getUserById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const result = await this.userService.getUserById(id);
      res.status(200).json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to get user';
      const statusCode = message.includes('404') || message.includes('not found') ? 404 : 500;
      res.status(statusCode).json({
        success: false,
        error: message,
      });
    }
  }

  /**
   * Proxy all other user-service routes
   */
  async proxyToUserService(req: Request, res: Response): Promise<void> {
    try {
      const path = req.path.replace('/api/users', '/api/users');
      const url = `${SERVICE_URLS.USER_SERVICE}${path}`;

      const response = await axios({
        method: req.method as any,
        url,
        data: req.body,
        params: req.query,
        headers: {
          ...req.headers,
          host: undefined, // Remove host header
        },
        timeout: 30000,
      });

      res.status(response.status).json(response.data);
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const status = error.response?.status || 500;
        const data = error.response?.data || { error: error.message };
        res.status(status).json(data);
      } else {
        res.status(500).json({
          success: false,
          error: 'Internal gateway error',
        });
      }
    }
  }
}
