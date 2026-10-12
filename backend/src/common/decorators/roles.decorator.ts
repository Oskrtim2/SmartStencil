import { SetMetadata } from '@nestjs/common';
import { UserRole } from '@prisma/client';

export const ROLES_KEY = 'roles';

/**
 * Decorator that restricts endpoint access to specific user roles.
 *
 * @example
 * ```ts
 * @Roles(UserRole.ARTIST)
 * @UseGuards(JwtAuthGuard, RolesGuard)
 * @Post('upload')
 * async uploadDesign() { ... }
 * ```
 */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
