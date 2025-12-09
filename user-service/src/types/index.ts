export interface User {
  id: string;
  balance: number;
}

export interface CreateUserDto {
  id?: string;
  balance?: number;
}

export interface UpdateUserDto {
  balance?: number;
}
