import { Injectable } from '@nestjs/common';
import { User, UserRole } from '@prisma/client';

import { PrismaService } from '../../../../common/prisma/prisma.service';

interface CreateUserWithProfileInput {
  email: string;
  passwordHash: string;
  displayName: string;
  role: UserRole;
}

/**
 * Repository for User aggregate in the Identity bounded context.
 *
 * Encapsulates all Prisma queries for User + associated profiles.
 * The service layer never touches Prisma directly.
 */
@Injectable()
export class UserRepository {
  constructor(private readonly prisma: PrismaService) { }

  /**
   * Find a user by email (case-insensitive).
   */
  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });
  }

  /**
   * Find a user by ID.
   */
  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  /**
   * Create a user and their role-specific profile in a single transaction.
   *
   * - ARTIST → creates ArtistProfile
   * - CLIENT → creates ClientProfile
   */
  async createWithProfile(input: CreateUserWithProfileInput): Promise<User> {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: input.email,
          passwordHash: input.passwordHash,
          displayName: input.displayName,
          role: input.role,
        },
      });

      if (input.role === UserRole.ARTIST) {
        await tx.artistProfile.create({
          data: { userId: user.id },
        });
      } else {
        await tx.clientProfile.create({
          data: { userId: user.id },
        });
      }

      return user;
    });
  }

  /**
   * Find a user with their artist profile.
   */
  async findWithArtistProfile(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      include: { artistProfile: true },
    });
  }

  /**
   * Find user with both possible profile relations for account management.
   */
  async findFullProfile(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
        role: true,
        avatarUrl: true,
        isActive: true,
        createdAt: true,
        artistProfile: true,
        clientProfile: true,
      },
    });
  }
}
