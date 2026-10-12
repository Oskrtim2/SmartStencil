import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Guard that validates JWT bearer tokens using the Passport JWT strategy.
 *
 * Applied at the controller or handler level:
 * ```ts
 * @UseGuards(JwtAuthGuard)
 * ```
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
