import { prisma } from '../config/database';
import bcrypt from 'bcryptjs';
import { CreateUserDto, UpdateUserDto } from '../types';

export class UserService {
  async createUser(data: CreateUserDto) {
    // Hash password
    // Check if user exists
    // Create user with prisma
    // Return user (without password)
  }

  async getUserById(id: string) {
    // Find user by id
    // Return user (without password)
  }

  async getUserByEmail(email: string) {
    // Find user by email
    // Return user (with password for auth)
  }

  async updateUser(id: string, data: UpdateUserDto) {
    // Update user
    // Return updated user (without password)
  }

  async deleteUser(id: string) {
    // Delete user
  }

  async validatePassword(plainPassword: string, hashedPassword: string) {
    // Use bcrypt.compare
  }
}
