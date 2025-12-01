import { prisma } from '../config/database.js';
import bcrypt from 'bcryptjs';
import type { CreateUserDto, UpdateUserDto } from '../types/index.js';

export class UserService {
  async createUser(data: CreateUserDto) {
    // If ID is provided (from gateway), check if user already exists
    if (data.id) {
      const existingUser = await prisma.user.findUnique({
        where: { id: data.id },
      });

      if (existingUser) {
        throw new Error('User with this ID already exists');
      }

      // Create user with provided ID and balance (called from gateway)
      const user = await prisma.user.create({
        data: {
          id: data.id,
          email: '', // Placeholder - not used when called from gateway
          username: '', // Placeholder - not used when called from gateway
          password: '', // Placeholder - not used when called from gateway
          balance: data.balance ?? 0,
        },
      });

      return { id: user.id, balance: user.balance };
    }

    // Original flow: Check if user with email or username already exists
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email: data.email },
          { username: data.username }
        ]
      }
    });

    if (existingUser) {
      throw new Error(
        existingUser.email === data.email 
          ? 'User with this email already exists'
          : 'User with this username already exists'
      );
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(data.password, 10);

    // Create user with prisma
    const user = await prisma.user.create({
      data: {
        email: data.email,
        username: data.username,
        password: hashedPassword,
        firstName: data.firstName ?? null,
        lastName: data.lastName ?? null,
        balance: data.balance ?? 0,
      },
    });

    // Return user (without password)
    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async getUserById(id: string) {
    // Find user by id
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new Error('User not found');
    }

    // Return user (without password)
    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async getUserByEmail(email: string) {
    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new Error('User not found');
    }

    // Return user (with password for auth)
    return user;
  }

  async updateUser(id: string, data: UpdateUserDto) {
    // Check if user exists
    const existingUser = await prisma.user.findUnique({
      where: { id },
    });

    if (!existingUser) {
      throw new Error('User not found');
    }

    // Check if email or username is being updated and already exists
    if (data.email || data.username) {
      const conflictingUser = await prisma.user.findFirst({
        where: {
          AND: [
            { id: { not: id } },
            {
              OR: [
                ...(data.email ? [{ email: data.email }] : []),
                ...(data.username ? [{ username: data.username }] : []),
              ],
            },
          ],
        },
      });

      if (conflictingUser) {
        throw new Error(
          conflictingUser.email === data.email
            ? 'User with this email already exists'
            : 'User with this username already exists'
        );
      }
    }

    // Update user
    const user = await prisma.user.update({
      where: { id },
      data: {
        ...(data.email && { email: data.email }),
        ...(data.username && { username: data.username }),
        ...(data.firstName !== undefined && { firstName: data.firstName }),
        ...(data.lastName !== undefined && { lastName: data.lastName }),
      },
    });

    // Return updated user (without password)
    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async deleteUser(id: string) {
    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new Error('User not found');
    }

    // Delete user
    await prisma.user.delete({
      where: { id },
    });
  }

  async validatePassword(plainPassword: string, hashedPassword: string): Promise<boolean> {
    // Use bcrypt.compare
    return await bcrypt.compare(plainPassword, hashedPassword);
  }
}
