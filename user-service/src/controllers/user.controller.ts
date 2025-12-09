import type { Request, Response } from 'express';
import { UserService } from '../services/user.service.js';

export class UserController {
  private userService = new UserService();

  async createUser(req: Request, res: Response): Promise<void> {
    try {
      const userData = req.body;

      const user = await this.userService.createUser(userData);

      res.status(201).json({
        success: true,
        data: user,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to create user';
      res.status(400).json({
        success: false,
        error: message,
      });
    }
  }

  async getUserById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;

      if (!id) {
        res.status(400).json({
          success: false,
          error: 'User ID is required',
        });
        return;
      }

      const user = await this.userService.getUserById(id);

      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'User not found';
      const statusCode = message === 'User not found' ? 404 : 500;
      
      res.status(statusCode).json({
        success: false,
        error: message,
      });
    }
  }

  async updateUser(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      
      if (!id) {
        res.status(400).json({
          success: false,
          error: 'User ID is required',
        });
        return;
      }

      const updateData = req.body;

      const user = await this.userService.updateUser(id, updateData);

      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to update user';
      const statusCode = message === 'User not found' ? 404 : 400;
      
      res.status(statusCode).json({
        success: false,
        error: message,
      });
    }
  }

  async deleteUser(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;

      if (!id) {
        res.status(400).json({
          success: false,
          error: 'User ID is required',
        });
        return;
      }

      await this.userService.deleteUser(id);

      res.status(204).send();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to delete user';
      const statusCode = message === 'User not found' ? 404 : 500;
      
      res.status(statusCode).json({
        success: false,
        error: message,
      });
    }
  }
}
