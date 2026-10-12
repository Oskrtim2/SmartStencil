import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { UserRepository } from '../../infrastructure/repositories/user.repository';
import { CreateUserDto, LoginDto, AuthResponseDto } from '../dto/auth.dto';

/**
 * Authentication service handling registration and login.
 *
 * Domain rules:
 * - Emails are unique across all users.
 * - Passwords are hashed with bcrypt (12 rounds).
 * - Artists get an ArtistProfile created on registration.
 * - Clients get a ClientProfile created on registration.
 * - JWT contains userId and role for stateless auth.
 */
@Injectable()
export class AuthService {
  private static readonly BCRYPT_ROUNDS = 12;

  constructor(
    private readonly userRepository: UserRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Register a new user with the specified role.
   */
  async register(dto: CreateUserDto): Promise<AuthResponseDto> {
    // Check email uniqueness
    const existing = await this.userRepository.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('An account with this email already exists');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(dto.password, AuthService.BCRYPT_ROUNDS);

    // Create user + role-specific profile in a transaction
    const user = await this.userRepository.createWithProfile({
      email: dto.email.toLowerCase().trim(),
      passwordHash,
      displayName: dto.displayName.trim(),
      role: dto.role,
    });

    // Generate tokens
    return this.generateTokens(user.id, user.role);
  }

  /**
   * Authenticate a user with email and password.
   */
  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const user = await this.userRepository.findByEmail(dto.email.toLowerCase().trim());
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account has been deactivated');
    }

    const passwordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    return this.generateTokens(user.id, user.role);
  }

  /**
   * Generate access + refresh JWT pair.
   */
  private generateTokens(userId: string, role: UserRole): AuthResponseDto {
    const payload = { sub: userId, role };

    const accessToken = this.jwtService.sign(payload);

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.refreshSecret'),
      expiresIn: this.configService.get<string>('jwt.refreshExpiration', '7d'),
    });

    return {
      accessToken,
      refreshToken,
      userId,
      role,
    };
  }
}
