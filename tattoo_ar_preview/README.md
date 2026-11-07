# SmartStencil

Probador de tatuajes en tiempo real, **100 % offline**, para Android e iOS.
La app usa la cámara trasera, importa diseños PNG con transparencia y compone
la tinta sobre la piel con un shader de multiplicación, conservando poros,
vellos, brillos y la iluminación real de la escena.

No hay backend, base de datos, autenticación ni peticiones de red. Todo el
procesamiento ocurre en el dispositivo.

## Funcionalidades

- Vista previa de la cámara trasera con autoenfoque y autoexposición.
- Composición a pantalla completa sin distorsión, con recorte tipo `cover` y
  soporte de rotación.
- Importación de diseños PNG con canal alfa desde la galería.
- Validación real del archivo: firma PNG, cabecera IHDR, canal alfa o `tRNS`,
  píxeles transparentes, tamaño máximo de 25 MB y textura máxima de 2048 px.
- Transformación multitáctil simultánea:
  - 1 dedo: arrastre.
  - 2 dedos: pellizco para escalar (0.22×–6×) y giro sobre el centro.
- Shader GLSL propio (`shaders/ink_blend.frag`) que multiplica la tinta contra
  la cámara y aplica la intensidad elegida.
- Control deslizante de intensidad de tinta de 0 % a 100 %.
- Captura de la composición a resolución de cámara, guardado temporal en caché
  y apertura inmediata del share sheet nativo para enviar a WhatsApp u otra app.
- Botón de disparo con flash visual, ocultación de controles durante la captura
  y confirmación por snackbar.
- Manejo de errores de permisos, cámara ausente, cámara en uso, PNG inválido,
  fallo de captura y fallo del shader.

## Stack

- Flutter 3.47.7 / Dart 3.13.5.
- `camera` 0.12.2.
- `image_picker` 1.2.4.
- `share_plus` 13.3.1.
- `path_provider` 2.1.6.
- `permission_handler` 11.4.0.

## Ejecutar

```bash
cd tattoo_ar_preview
flutter pub get
flutter run
```

## Compilar APK debug

```bash
cd tattoo_ar_preview
flutter build apk --debug
```

El APK se genera en:

```text
tattoo_ar_preview/build/app/outputs/flutter-apk/app-debug.apk
```

## Compilar iOS

Requiere macOS con Xcode y CocoaPods:

```bash
cd tattoo_ar_preview
flutter pub get
cd ios && pod install && cd ..
flutter build ios --no-codesign
```

El `Podfile` ya declara `PERMISSION_CAMERA=1` y `PERMISSION_PHOTOS=1` para
`permission_handler_apple`. El `Info.plist` incluye las descripciones de uso de
cámara y fotos exigidas por iOS.

## Permisos

Android (`android/app/src/main/AndroidManifest.xml`):

- `CAMERA`.
- `READ_EXTERNAL_STORAGE` con `maxSdkVersion=32`.
- `READ_MEDIA_IMAGES`.
- `uses-feature` de cámara y autoenfoque como opcionales.

iOS (`ios/Runner/Info.plist`):

- `NSCameraUsageDescription`.
- `NSPhotoLibraryUsageDescription`.
- `NSPhotoLibraryAddUsageDescription`.

La app solicita cámara con `permission_handler`; la galería usa el selector del
sistema de `image_picker`. En iOS se solicita además acceso a Fotos, pero el
selector PHPicker puede continuar aunque el permiso no se conceda.

## Cómo se compone la tinta

1. El `CameraPreview` se muestra a pantalla completa con `FittedBox.cover`.
2. `TattooInkMask` envuelve la cámara con un `ShaderMask` y
   `BlendMode.multiply`.
3. El shader recibe la textura PNG, el centro, el tamaño base, la escala, la
   rotación y la opacidad. Fuera del rectángulo del tatuaje devuelve alfa 0.
4. El color de salida está premultiplicado:
   `rgb = texel.rgb * opacity`, `alpha = texel.a * opacity`.
5. El resultado compositado es equivalente a `piel × tinta`, por lo que la
   textura de la piel permanece visible.

La captura usa la foto nativa de la cámara (`takePicture`), la recorta con el
mismo encuadre `cover`, aplica el mismo shader sobre un `Canvas` y genera un PNG
de hasta 2560 px de lado largo. Si la foto falla, se usa un fallback mediante
`RepaintBoundary.toImage`. Después se guarda en el directorio temporal y se
abre `SharePlus.instance.share(...)`.

## Estructura

```text
lib/
  app.dart
  main.dart
  core/
    errors/app_failure.dart
    permissions/permission_service.dart
    theme/app_theme.dart
  features/
    bootstrap/presentation/shader_bootstrap.dart
    camera/
      data/camera_session.dart
      presentation/camera_status_view.dart
      presentation/camera_viewfinder.dart
    capture/
      data/capture_service.dart
      domain/capture_geometry.dart
    editor/
      presentation/tattoo_editor_screen.dart
      presentation/widgets/editor_top_bar.dart
      presentation/widgets/ink_controls.dart
    tattoo/
      data/tattoo_repository.dart
      domain/tattoo_gesture_controller.dart
      domain/tattoo_transform.dart
      presentation/tattoo_ink_mask.dart
      rendering/ink_shader.dart
shaders/
  ink_blend.frag
test/
  capture_geometry_test.dart
  png_validation_test.dart
  tattoo_gesture_controller_test.dart
  tattoo_transform_test.dart
```

## Pruebas

```bash
cd tattoo_ar_preview
flutter test
dart analyze lib test
```

La suite cubre los límites de escala/traslación, el plegado de rotación, los
gestos multitáctiles, la geometría de recorte de captura y la firma PNG.

## Privacidad y almacenamiento

- Sin red, sin analytics, sin cuentas.
- Las capturas se guardan en el directorio temporal de la app.
- Se conservan como máximo las 5 capturas más recientes; las anteriores se
  eliminan automáticamente.
- El diseño importado y la captura nunca salen del dispositivo salvo que el
  usuario elija una app en el share sheet del sistema.

## Notas de compilación para Windows

El workspace de este repositorio contiene `diseño` en la ruta. Algunas
herramientas de Android no admiten rutas no ASCII:

- `android/gradle.properties` incluye `android.overridePathCheck=true`.
- `permission_handler` se fija a `11.4.0` porque `13.x` exige Android SDK 37.
- `path_provider_android` se fija a `2.2.23` mediante `dependency_overrides`
  porque `2.3.x` usa JNI/CMake y falla con rutas no ASCII en Windows. En macOS
  o Linux se puede retirar el override si se desea la última implementación.
