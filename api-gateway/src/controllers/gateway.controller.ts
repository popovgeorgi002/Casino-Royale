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
      // req.path will be '/users/:id' when mounted at '/gateway' or '/api'
      // We need to construct the full path to user-service
      const path = req.path; // This will be '/users/:id' or '/users'
      const url = `${SERVICE_URLS.USER_SERVICE}/api${path}`;

      // Use ClusterIP directly to avoid DNS issues
      const serviceUrl = process.env.USER_SERVICE_URL || 'http://10.96.153.220:3000';
      const finalUrl = `${serviceUrl}/api${path}`;
      
      console.log(`[GATEWAY] Proxying ${req.method} ${req.path} to ${finalUrl}`);
      console.log(`[GATEWAY] Request body:`, JSON.stringify(req.body));

      const response = await axios({
        method: req.method as any,
        url: finalUrl,
        data: req.body,
        params: req.query,
        headers: {
          'Content-Type': 'application/json',
          ...(req.headers.authorization && { Authorization: req.headers.authorization }),
        },
        timeout: 30000,
        validateStatus: () => true,
      });

      console.log(`[GATEWAY] Response status: ${response.status}`);
      console.log(`[GATEWAY] Response data:`, JSON.stringify(response.data));

      res.status(response.status).json(response.data);
    } catch (error) {
      console.error('[GATEWAY] Proxy error details:', error);
      if (axios.isAxiosError(error)) {
        const status = error.response?.status || 500;
        const data = error.response?.data || { error: error.message };
        console.error(`[GATEWAY] Proxy error: ${status}`, data);
        res.status(status).json(data);
      } else {
        console.error('[GATEWAY] Internal proxy error:', error);
        res.status(500).json({
          success: false,
          error: error instanceof Error ? error.message : 'Internal gateway error',
        });
      }
    }
  }

  /**
   * Proxy requests to deposit-service
   */
  async proxyToDepositService(req: Request, res: Response): Promise<void> {
    try {
      // req.path will be '/deposits' or '/deposits/:id' when mounted at '/api'
      // We need to forward to '/api/deposits' on the deposit service
      const path = req.path.startsWith('/deposits') 
        ? req.path.replace('/deposits', '/api/deposits')
        : `/api${req.path}`;
      const url = `${SERVICE_URLS.DEPOSIT_SERVICE}${path}`;

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
