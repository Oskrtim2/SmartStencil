import { IsEmail, IsEnum, IsString, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

export class CreateUserDto {
  @ApiProperty({ example: 'artist@inksight.app' })
  @IsEmail({}, { message: 'El correo electrónico no es válido' })
  email!: string;

  @ApiProperty({ example: 'Pass123', description: 'Contraseña de 6 a 15 caracteres' })
  @IsString()
  @MinLength(6, { message: 'La contraseña debe tener mínimo 6 caracteres' })
  @MaxLength(15, { message: 'La contraseña debe tener máximo 15 caracteres' })
  password!: string;

  @ApiProperty({ example: 'Kai Nakamura' })
  @IsString()
  @MinLength(2, { message: 'El nombre debe tener al menos 2 caracteres' })
  @MaxLength(100)
  displayName!: string;

  @ApiProperty({ enum: UserRole, example: UserRole.ARTIST })
  @IsEnum(UserRole, { message: 'El rol debe ser ARTIST o CLIENT' })
  role!: UserRole;
}

export class LoginDto {
  @ApiProperty({ example: 'artist@inksight.app' })
  @IsString()
  email!: string;

  @ApiProperty({ example: 'Pass123', description: 'Contraseña de 6 a 15 caracteres' })
  @IsString()
  @MinLength(6, { message: 'La contraseña debe tener mínimo 6 caracteres' })
  @MaxLength(15, { message: 'La contraseña debe tener máximo 15 caracteres' })
  password!: string;
}

export class AuthResponseDto {
  @ApiProperty()
  accessToken!: string;

  @ApiProperty()
  refreshToken!: string;

  @ApiProperty()
  userId!: string;

  @ApiProperty({ enum: UserRole })
  role!: UserRole;

  @ApiProperty({ example: 'Kai Nakamura' })
  displayName?: string;

  @ApiProperty({ example: 'artist@inksight.app' })
  email?: string;
}
