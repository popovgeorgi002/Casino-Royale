export interface User {
  id: string;
  balance: number;
}

export interface CreateUserDto {
  id?: string; // Optional - if provided, use this ID (for external creation)
  balance?: number; // Optional - defaults to 0
}

export interface UpdateUserDto {
  balance?: number;
}
