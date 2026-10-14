# InkSight — Project Repository Map

## Repository Structure

```
smarthphone/
├── mobile/                                          # Flutter cross-platform app
│   ├── pubspec.yaml                                 # Dependencies & shader registration
│   ├── shaders/
│   │   └── multiply_blend.frag                      # GLSL multiply-blend + MSAA shader
│   └── lib/
│       ├── main.dart                                # Entry point (Riverpod, portrait lock)
│       ├── app.dart                                 # MaterialApp + routing
│       ├── core/
│       │   ├── ar/
│       │   │   ├── ar_platform_bridge.dart          # Abstract ARKit/ARCore bridge
│       │   │   ├── ar_session_controller.dart       # Top-level AR orchestrator
│       │   │   ├── cylindrical_mapper.dart          # Curved surface UV mapping
│       │   │   └── surface_tracker.dart             # Anchor detection + selection
│       │   ├── gestures/
│       │   │   └── tattoo_gesture_controller.dart   # Simultaneous pan/pinch/rotate
│       │   └── network/
│       │       ├── api_client.dart                  # Dio HTTP client + JWT interceptors
│       │       └── secure_image_loader.dart         # Memory-only PNG loader (no disk)
│       ├── features/
│       │   ├── ar_preview/
│       │   │   ├── presentation/
│       │   │   │   ├── ar_preview_screen.dart       # Main AR screen + controls
│       │   │   │   └── widgets/
│       │   │   │       ├── ar_viewport.dart          # Shader rendering widget
│       │   │   │       └── opacity_slider.dart       # Glass-style opacity control
│       │   │   └── providers/
│       │   │       └── ar_preview_provider.dart      # Riverpod DI providers
│       │   └── qr_scanner/
│       │       └── presentation/
│       │           └── qr_scanner_screen.dart        # QR scanner + token extraction
│       └── shared/
│           ├── models/
│           │   └── design_model.dart                 # Client-side design DTO
│           └── theme/
│               └── app_theme.dart                    # Dark theme (violet + cyan)
│
├── backend/                                          # NestJS DDD API
│   ├── package.json                                  # Dependencies
│   ├── tsconfig.json                                 # TypeScript strict config
│   ├── nest-cli.json                                 # NestJS CLI config
│   ├── .env.example                                  # Environment variables template
│   ├── prisma/
│   │   └── schema.prisma                             # Database schema (3 bounded contexts)
│   └── src/
│       ├── main.ts                                   # Bootstrap + Swagger + CORS
│       ├── app.module.ts                             # Root module (config, throttler, DDD)
│       ├── config/
│       │   ├── app.config.ts                         # Typed config namespaces
│       │   └── validation.schema.ts                  # Joi env validation
│       ├── common/
│       │   ├── prisma/
│       │   │   ├── prisma.service.ts                 # PrismaClient lifecycle
│       │   │   └── prisma.module.ts                  # Global Prisma provider
│       │   ├── guards/
│       │   │   ├── jwt-auth.guard.ts                 # JWT bearer validation
│       │   │   └── roles.guard.ts                    # Role-based access control
│       │   └── decorators/
│       │       └── roles.decorator.ts                # @Roles() metadata decorator
│       └── modules/
│           ├── identity/                             # Bounded Context: Identity
│           │   ├── identity.module.ts
│           │   ├── application/
│           │   │   ├── dto/auth.dto.ts               # CreateUser, Login, AuthResponse
│           │   │   └── services/auth.service.ts      # Register, login, JWT generation
│           │   └── infrastructure/
│           │       ├── controllers/auth.controller.ts
│           │       ├── repositories/user.repository.ts
│           │       └── strategies/jwt.strategy.ts    # Passport JWT validation
│           ├── catalog/                              # Bounded Context: Catalog
│           │   ├── catalog.module.ts
│           │   ├── application/
│           │   │   ├── dto/design.dto.ts             # Create, Response, ListQuery
│           │   │   └── services/
│           │   │       ├── design.service.ts         # Upload, CRUD, PNG validation
│           │   │       └── s3-storage.service.ts     # S3 upload, presigned URLs, delete
│           │   └── infrastructure/
│           │       ├── controllers/design.controller.ts
│           │       └── repositories/design.repository.ts
│           └── sharing/                              # Bounded Context: Sharing
│               ├── sharing.module.ts
│               ├── application/
│               │   ├── dto/sharing.dto.ts            # CreateShare, ShareResponse, SharedDesign
│               │   └── services/sharing.service.ts   # Token creation, atomic consumption, QR
│               └── infrastructure/
│                   └── controllers/sharing.controller.ts
```

## API Endpoints

| Method | Path | Auth | Role | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/v1/auth/register` | — | — | Register artist or client (password 6-15 chars) |
| `POST` | `/api/v1/auth/login` | — | — | Login → JWT pair (password 6-15 chars) |
| `GET` | `/api/v1/auth/me` | JWT | — | Get authenticated profile & role details |
| `POST` | `/api/v1/ai/generate-stencil` | JWT | — | **AI Text-to-Stencil**: Vector PNG + anatomical advice |
| `POST` | `/api/v1/designs` | JWT | ARTIST | Upload design (multipart PNG) |
| `GET` | `/api/v1/designs` | JWT | ARTIST | List my designs |
| `GET` | `/api/v1/designs/:id` | JWT | ARTIST | Get design details |
| `POST` | `/api/v1/designs/:id/publish` | JWT | ARTIST | Publish design |
| `DELETE` | `/api/v1/designs/:id` | JWT | ARTIST | Delete design + S3 asset |
| `POST` | `/api/v1/sharing/create` | JWT | ARTIST | Generate share token + QR |
| `GET` | `/api/v1/sharing/consume/:token` | — | — | **Public** — consume token, get presigned URL |
| `DELETE` | `/api/v1/sharing/:id/revoke` | JWT | ARTIST | Revoke a share token |

## Getting Started

### Backend
```bash
cd backend
cp .env.example .env          # Configure your environment
npm install
npx prisma generate           # Generate Prisma client
npx prisma migrate dev        # Run migrations
npm run start:dev             # Start with hot-reload
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run                    # Run on connected device/emulator
```

> [!IMPORTANT]
> The mobile app requires a physical device with ARCore (Android) or ARKit (iOS) support. AR features will not work in simulators/emulators.

## Next Steps

| Priority | Task | Context |
|----------|------|---------|
| 🔴 High | Implement concrete `ArPlatformBridge` for iOS (ARKit) and Android (ARCore) | Platform channel implementations in `ios/` and `android/` |
| 🔴 High | Wire LiDAR mesh vertices into `CylindricalMapper.fitFromMeshVertices()` | Currently falls through to plane estimate |
| 🟡 Medium | Add thumbnail generation pipeline (Sharp/ImageMagick on upload) | Backend — design service |
| 🟡 Medium | Implement token refresh flow in mobile API client | 401 interceptor in `api_client.dart` |
| 🟢 Low | Add artist portfolio/gallery screens to mobile | New feature module |
| 🟢 Low | CI/CD pipeline for both mobile and backend | GitHub Actions / Fastlane |
