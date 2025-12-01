export interface User {
  id: string;
  email: string;
  username: string;
  password?: string; // Optional when returning to client
  firstName?: string;
  lastName?: string;
  balance: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateUserDto {
  id?: string; // Optional - if provided, use this ID (for external creation)
  email: string;
  username: string;
  password: string;
  firstName?: string;
  lastName?: string;
  balance?: number; // Optional - defaults to 0
}

export interface UpdateUserDto {
  email?: string;
  username?: string;
  firstName?: string;
  lastName?: string;
}

export interface LoginDto {
  email: string;
  password: string;
}
