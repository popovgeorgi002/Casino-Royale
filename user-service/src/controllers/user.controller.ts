import { Request, Response } from 'express';
import { UserService } from '../services/user.service';

export class UserController {
  private userService = new UserService();

  async createUser(req: Request, res: Response) {
    // Extract data from req.body
    // Call userService.createUser
    // Return 201 with created user
  }

  async getUserById(req: Request, res: Response) {
    // Get id from req.params
    // Call userService.getUserById
    // Return 200 with user or 404
  }

  async updateUser(req: Request, res: Response) {
    // Get id from req.params
    // Get data from req.body
    // Call userService.updateUser
    // Return 200 with updated user
  }

  async deleteUser(req: Request, res: Response) {
    // Get id from req.params
    // Call userService.deleteUser
    // Return 204
  }
}
