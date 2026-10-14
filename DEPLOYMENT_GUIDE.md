# 🚀 Guía Maestra de Despliegue — InkSight AR Tattoo Preview

Esta guía detalla paso a paso cómo poner en marcha y desplegar la solución completa de **InkSight**, compuesta por dos capas principales:
1. **Backend API (NestJS + PostgreSQL + MinIO / AWS S3)**
2. **Cliente Móvil de Realidad Aumentada (Flutter para Android e iOS)**

---

## 🗺️ Mapa General del Despliegue

```
┌────────────────────────────────────────┐
│        Nube o Servidor Local           │
│                                        │
│  [PostgreSQL :5432] ◄──┐               │
│                        ▼               │
│  [MinIO/S3 :9000]   ◄──► [NestJS :3000]│
└───────────────────────────▲────────────┘
                            │ HTTP REST / JWT
┌───────────────────────────▼────────────┐
│             Cliente Móvil              │
│                                        │
│  [Dispositivo Android / iOS]           │
│  ├── Cámara + Sensores (ARCore/ARKit) │
│  └── Shaders GLSL (Multiply-Blend)     │
└────────────────────────────────────────┘
```

---

## 📦 PARTE 1: Despliegue del Backend

### Opción A: Despliegue Local con Docker Compose (Recomendado para pruebas locales)

Se ha creado un archivo `docker-compose.yml` en la raíz del proyecto que levanta:
- **PostgreSQL 16** (puerto `5432`)
- **MinIO** (almacenamiento S3 local en puerto `9000` y consola visual en `http://localhost:9001`)
- **NestJS API** (puerto `3000`)

#### Pasos:
1. Abre tu terminal en la carpeta principal del proyecto:
   ```bash
   docker compose up -d
   ```
2. Entra a `http://localhost:9001` (Usuario: `minioadmin` / Clave: `minioadminpassword`) y crea el bucket `inksight-designs`.
3. Ejecuta las migraciones de base de datos de Prisma:
   ```bash
   cd backend
   npm install
   npx prisma migrate dev --name init
   ```
4. Explora la documentación interactiva Swagger:
   `http://localhost:3000/api/docs`

---

### Opción B: Despliegue en la Nube Gratuito (Render + Supabase / Neon)

1. **Base de Datos (Supabase / Neon):**
   - Crea un proyecto en [Supabase.com](https://supabase.com/) o [Neon.tech](https://neon.tech/).
   - Copia la URL de conexión (`DATABASE_URL`).
2. **Servidor API (Render.com):**
   - Crea un **Web Service** conectado a tu repositorio en [Render.com](https://render.com/).
   - Directorio raíz: `backend`
   - Build Command: `npm install && npx prisma generate && npm run build`
   - Start Command: `npx prisma migrate deploy && npm run start:prod`
   - Variables de entorno:
     - `DATABASE_URL`: tu URL de Supabase/Neon
     - `JWT_SECRET`: clave aleatoria segura de 32+ caracteres
     - `JWT_REFRESH_SECRET`: clave de refresco de 32+ caracteres
     - `PORT`: `3000`

---

## 📱 PARTE 2: Preparación y Despliegue de la App Móvil (Flutter)

*Nota: La Realidad Aumentada requiere cámara física y giroscopio/sensores, por lo que debe ejecutarse en un teléfono real.*

### Paso 1: Instalar Flutter en tu PC
1. Descarga e instala Flutter desde [flutter.dev](https://flutter.dev/docs/get-started/install/windows).
2. Agrega `flutter\bin` al PATH del sistema en Windows.
3. Verifica la instalación ejecutando:
   ```bash
   flutter doctor
   ```

### Paso 2: Generar el Soporte Nativo (`android/` e `ios/`)
En la terminal, dentro de la carpeta `mobile`:
```bash
cd mobile
flutter create . --org com.inksight
```

### Paso 3: Configurar Permisos AR
- **Android (`android/app/src/main/AndroidManifest.xml`):**
  Agrega los permisos de cámara y ARCore:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-feature android:name="android.hardware.camera.ar" android:required="true" />
  ```
  Y dentro de `<application>`:
  ```xml
  <meta-data android:name="com.google.ar.core" android:value="required" />
  ```

- **iOS (`ios/Runner/Info.plist`):**
  Agrega en `<dict>`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>InkSight requiere la cámara para proyectar tatuajes en Realidad Aumentada.</string>
  ```

### Paso 4: Configurar la URL de la API en el Móvil
En `mobile/lib/core/network/api_client.dart`:
- Si desplegaste en Render: usa `https://tu-app.onrender.com`.
- Si pruebas en red local: usa tu IP de la computadora (ej. `http://192.168.1.X:3000`), **nunca uses localhost en el móvil**.

### Paso 5: Ejecutar en el Teléfono Celular
1. En tu teléfono Android, activa **Opciones de desarrollador** y habilita **Depuración por USB**.
2. Conéctalo por cable USB a la computadora.
3. Ejecuta:
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

### Paso 6: Generar el APK Instalable
Para generar el archivo instalable e instalarlo directamente en cualquier teléfono Android:
```bash
flutter build apk --release
```
El archivo generado estará listo en:
`mobile/build/app/outputs/flutter-apk/app-release.apk`
