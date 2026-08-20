import type { UserRepository } from '../repositories/userRepository.js';
import { hashPassword } from '../utils/password.js';

export class UserService {
  constructor(private userRepo: UserRepository) {}

  list(params: { role?: string; search?: string; page?: number; pageSize?: number }) {
    return this.userRepo.list(params);
  }

  async create(input: { email: string; password: string; fullName: string; phone: string; role: string }) {
    const passwordHash = await hashPassword(input.password);
    return this.userRepo.create({ ...input, passwordHash });
  }

  setRole(id: string, role: string) {
    return this.userRepo.setRole(id, role);
  }

  setActive(id: string, isActive: boolean) {
    return this.userRepo.setActive(id, isActive);
  }
}
