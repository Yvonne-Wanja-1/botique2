import type { UserRepository, UserRow } from '../repositories/userRepository.js';
import { UnauthorizedError } from '../utils/errors.js';
import { hashPassword, verifyPassword } from '../utils/password.js';
import { signToken } from '../middleware/auth.js';

export interface AuthResult {
  token: string;
  user: UserRow;
}

export interface RegisterInput {
  fullName: string;
  email: string;
  phone: string;
  password: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

export class AuthService {
  constructor(
    private userRepo: UserRepository,
    private jwtSecret: string,
    private jwtExpiresIn: string,
  ) {}

  private issue(user: UserRow): AuthResult {
    const token = signToken({ userId: user.id, role: user.role }, this.jwtSecret, this.jwtExpiresIn);
    return { token, user };
  }

  /**
   * Public self-registration. The role is always forced to `customer`;
   * privileged roles can only be assigned by an admin via the staff endpoint.
   */
  async register(input: RegisterInput): Promise<AuthResult> {
    const email = input.email.trim().toLowerCase();
    const passwordHash = await hashPassword(input.password);
    const user = await this.userRepo.create({
      email,
      phone: input.phone,
      fullName: input.fullName,
      role: 'customer',
      passwordHash,
    });
    return this.issue(user);
  }

  async login(input: LoginInput): Promise<AuthResult> {
    const email = input.email.trim().toLowerCase();
    const record = await this.userRepo.findByEmailWithPassword(email);
    const passwordOk = record?.passwordHash
      ? await verifyPassword(input.password, record.passwordHash)
      : false;
    if (!record || !passwordOk) {
      throw new UnauthorizedError('Incorrect email or password');
    }
    if (!record.isActive) {
      throw new UnauthorizedError('This account has been deactivated. Please contact support.');
    }
    const { passwordHash: _passwordHash, ...user } = record;
    return this.issue(user);
  }

  async me(userId: string): Promise<UserRow> {
    const user = await this.userRepo.getById(userId);
    if (!user) throw new UnauthorizedError('This account no longer exists');
    return user;
  }

  async updateAvatar(userId: string, avatarUrl: string): Promise<UserRow> {
    return this.userRepo.updateAvatar(userId, avatarUrl);
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string): Promise<void> {
    const hash = await this.userRepo.getPasswordHash(userId);
    if (!hash || !(await verifyPassword(currentPassword, hash))) {
      throw new UnauthorizedError('Incorrect current password');
    }
    const newHash = await hashPassword(newPassword);
    await this.userRepo.updatePassword(userId, newHash);
  }
}
