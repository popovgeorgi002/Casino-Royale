import type { Request, Response } from 'express';
import { UserService } from '../services/user.service.js';

export class UserController {
  private userService = new UserService();

  async createUser(req: Request, res: Response): Promise<void> {
    try {
      // Extract data from req.body
      const userData = req.body;

      // Call userService.createUser
      const user = await this.userService.createUser(userData);

      // Return 201 with created user
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
      // Get id from req.params
      const { id } = req.params;

      if (!id) {
        res.status(400).json({
          success: false,
          error: 'User ID is required',
        });
        return;
      }

      // Call userService.getUserById
      const user = await this.userService.getUserById(id);

      // Return 200 with user
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
      // Get id from req.params
      const { id } = req.params;
      
      if (!id) {
        res.status(400).json({
          success: false,
          error: 'User ID is required',
        });
        return;
      }

      // Get data from req.body
      const updateData = req.body;

      // Call userService.updateUser
      const user = await this.userService.updateUser(id, updateData);

      // Return 200 with updated user
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
      // Get id from req.params
      const { id } = req.params;

      if (!id) {
        res.status(400).json({
          success: false,
          error: 'User ID is required',
        });
        return;
      }

      // Call userService.deleteUser
      await this.userService.deleteUser(id);

      // Return 204
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
