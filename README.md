# 🖋️ SmartStencil — Augmented Reality Tattoo Preview Platform

**SmartStencil** is a cross-platform mobile application and backend platform designed for tattoo artists and clients. It allows high-resolution tattoo designs to be previewed directly on curved human skin (such as forearms and legs) in real-time through the device camera using Augmented Reality and custom fragment shaders.

---

## 🏗️ Architecture Overview

The platform consists of two decoupled subsystems:

### 1. Mobile Client (`/mobile`)
- **Framework:** Flutter (Dart)
- **AR Engine:** ARCore (Android) / ARKit (iOS) with cylindrical surface fitting for limb anatomy
- **Shaders:** Custom GLSL fragment shader (`multiply_blend.frag`) that reproduces ink absorption into the skin's dermal layer with 4x MSAA
- **Gestures:** Multi-touch simultaneous drag, pinch-to-scale, and two-finger rotation
- **Security:** Memory-only design rendering with in-place byte wiping to protect artist intellectual property

### 2. Backend API (`/backend`)
- **Framework:** NestJS (TypeScript) following Domain-Driven Design (DDD) principles
- **ORM & Database:** Prisma ORM with PostgreSQL
- **Object Storage:** AWS S3 (or MinIO for local development) with presigned, time-limited URLs
- **Authentication:** JWT with role-based access control (`ARTIST` and `CLIENT`)
- **Sharing Engine:** Cryptographic share tokens with QR code generation and configurable TTL / max-use limits

---

## 📁 Repository Structure

```
.
├── backend/                  # NestJS REST API
│   ├── prisma/               # Database schema & migrations
│   ├── src/
│   │   ├── config/           # Environment & security config
│   │   ├── common/           # Guards, decorators, prisma service
│   │   └── modules/
│   │       ├── identity/     # Auth, users, artist/client profiles
│   │       ├── catalog/      # Tattoo designs, tags, S3 storage
│   │       └── sharing/      # QR share tokens & validation
│   ├── Dockerfile            # Production container build
│   └── package.json
│
├── mobile/                   # Flutter cross-platform client
│   ├── lib/
│   │   ├── core/
│   │   │   ├── ar/           # AR session, cylindrical mapping, bridges
│   │   │   ├── gestures/     # Simultaneous pan/scale/rotate
│   │   │   └── network/      # HTTP client & secure image decoding
│   │   ├── features/
│   │   │   ├── ar_preview/   # AR viewport & interactive preview
│   │   │   └── qr_scanner/   # QR scanning screen
│   │   └── shared/           # Models, dark theme, UI tokens
│   ├── shaders/              # GLSL fragment shaders
│   ├── android/              # Native Android configuration (ARCore)
│   ├── ios/                  # Native iOS configuration (ARKit)
│   └── pubspec.yaml
│
└── docker-compose.yml        # Local orchestration (PostgreSQL + MinIO + API)
```

---

## 🚀 Quick Start

### Backend (Local with Docker)

```bash
# 1. Start PostgreSQL, MinIO, and API
docker compose up -d

# 2. Run database migrations
cd backend
npm install
npx prisma migrate dev --name init

# 3. Explore API Documentation
# Open http://localhost:3000/api/docs
```

### Mobile App (Physical Device)

```bash
cd mobile

# 1. Install dependencies
flutter pub get

# 2. Run on connected device (enable USB Debugging)
flutter run

# 3. Build release APK
flutter build apk --release
```

---

## 🔒 Security & Privacy

- All tattoo assets are transferred via temporary presigned URLs (default 5-minute TTL).
- Original high-resolution design files are never cached on the client filesystem.
- Cryptographic single-use / limited-use share tokens prevent unauthorized distribution.
