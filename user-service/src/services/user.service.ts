import { prisma } from '../config/database.js';
import type { CreateUserDto, UpdateUserDto } from '../types/index.js';

export class UserService {
  async createUser(data: CreateUserDto) {
    if (data.id) {
      const existingUser = await prisma.user.findUnique({
        where: { id: data.id },
      });

      if (existingUser) {
        throw new Error('User with this ID already exists');
      }

      const user = await prisma.user.create({
        data: {
          id: data.id,
          balance: data.balance ?? 0,
        },
      });

      return { id: user.id, balance: user.balance };
    }

    const user = await prisma.user.create({
      data: {
        balance: data.balance ?? 0,
      },
    });

    return { id: user.id, balance: user.balance };
  }

  async getUserById(id: string) {
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new Error('User not found');
    }

    return { id: user.id, balance: user.balance };
  }

  async updateUser(id: string, data: UpdateUserDto) {
    const existingUser = await prisma.user.findUnique({
      where: { id },
    });

    if (!existingUser) {
      throw new Error('User not found');
    }

    const user = await prisma.user.update({
      where: { id },
      data: {
        ...(data.balance !== undefined && { balance: data.balance }),
      },
    });

    return { id: user.id, balance: user.balance };
  }

  async deleteUser(id: string) {
    const user = await prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new Error('User not found');
    }

    await prisma.user.delete({
      where: { id },
    });
  }
}
