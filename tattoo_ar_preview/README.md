# SmartStencil

Probador de tatuajes en tiempo real, **100 % offline**, para Android e iOS.
La app usa la cámara trasera, importa **cualquier imagen** (PNG, JPG, WebP,
HEIC…), la convierte en un **stencil negro transparente** y compone la tinta
sobre la piel con un shader de multiplicación, conservando poros, vellos, brillos
y la iluminación real de la escena.

No hay backend, base de datos, autenticación ni peticiones de red. Todo el
procesamiento, incluida la IA de segmentación de fondo, ocurre en el dispositivo.

## Funcionalidades

- Vista previa de la cámara trasera con autoenfoque y autoexposición.
- Composición a pantalla completa sin distorsión, con recorte tipo `cover` y
  soporte de rotación.
- Importación de **cualquier formato de imagen** que el decodificador del
  sistema pueda leer: PNG, JPEG, WebP, HEIC, GIF, BMP…
- Conversión automática a un stencil transparente:
  - PNG con transparencia: conserva el alfa y convierte cualquier color en tinta
    negra.
  - Fondo plano: detecta el color dominante del borde, lo elimina y convierte
    las líneas de color en negro.
  - Fondo complejo: un modelo **U2-Net ONNX de 4.6 MB empaquetado en la app**
    elimina el fondo on-device sin descargas ni red; después se extraen los
    contornos y se limpian los elementos pequeños.
- Eliminación de ruido, componentes aislados y márgenes vacíos antes de cargar el
  stencil.
- Exportación del stencil procesado como **PNG transparente** mediante el share
  sheet nativo.
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
- Manejo de errores de permisos, cámara ausente, cámara en uso, formato no
  soportado, fallo de conversión/captura y fallo del shader.

## Stack

- Flutter 3.47.7 / Dart 3.13.5.
- `camera` 0.12.2.
- `image_picker` 1.2.4.
- `share_plus` 13.3.1.
- `path_provider` 2.1.6.
- `permission_handler` 11.4.0.
- `image_background_remover` 2.0.1 con U2-Net ONNX empaquetado (4.6 MB).
- `flutter_onnxruntime` 1.9.0.

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

Requiere macOS con Xcode y CocoaPods. SmartStencil usa iOS 16+ por el runtime
ONNX:

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

## Conversión local a stencil

1. La imagen se decodifica con el códec de Flutter a RGBA, limitada a 2048 px
   en el lado largo.
2. Si ya tiene transparencia, se conserva su alfa y los colores se convierten en
   negro.
3. Si el borde tiene un color plano dominante (papel blanco, fondo de color),
   ese fondo se elimina por distancia de color y las líneas de color se
   convierten en negro.
4. Si el fondo es complejo (foto, degradado), se ejecuta **U2-Net** mediante
   ONNX Runtime con el modelo empaquetado en la app. La máscara resultante se
   procesa con detección de bordes para conservar el line-art y evitar rellenar
   zonas planas del sujeto.
5. El resultado pasa por una limpieza de componentes pequeños, eliminación de
   márgenes vacíos y generación de un PNG/`ui.Image` transparente.
6. El usuario puede compartir ese stencil como PNG desde la barra superior.

La inferencia y el procesamiento de píxeles se hacen en el dispositivo. El
modelo no se descarga en tiempo de ejecución; viaja dentro del APK/IPA.

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
      data/stencil_export_service.dart
      data/tattoo_repository.dart
      domain/tattoo_gesture_controller.dart
      domain/tattoo_transform.dart
      presentation/tattoo_ink_mask.dart
      processing/background_analysis.dart
      processing/background_removal_engine.dart
      processing/stencil_processor.dart
      rendering/ink_shader.dart
shaders/
  ink_blend.frag
test/
  background_analysis_test.dart
  capture_geometry_test.dart
  capture_result_test.dart
  ink_controls_test.dart
  png_validation_test.dart
  stencil_processor_test.dart
  tattoo_gesture_controller_test.dart
  tattoo_transform_test.dart
```

## Pruebas

```bash
cd tattoo_ar_preview
flutter test
dart analyze lib test
dart format --output=none --set-exit-if-changed lib test
```

La suite incluye 63 pruebas y cubre límites de escala/traslación, valores no
finitos, gestos multitáctiles incrementales, rebase por cambio de viewport,
geometría de recorte y relaciones de aspecto extremas, análisis de fondos
planos/gradientes, conversión de color a tinta, preservación de alfa, eliminación
de ruido y recorte, extracción de bordes en modo IA, guardas de concurrencia,
nombres de archivo, permisos y timeouts de cámara, mensajes de resultado,
controles de tinta y tamaño base del shader.

El repositorio incluye un workflow de GitHub Actions
(`.github/workflows/flutter-ci.yml`) que comprueba formato, análisis, pruebas y
el build del APK debug.

## Endurecimiento

- Timeouts en la inicialización de cámara y en la carga del shader.
- Recuperación de resultados de galería perdidos por recreación de actividad.
- Guard de captura para impedir operaciones concurrentes.
- Verificación de escrituras completas y mensajes específicos de almacenamiento.
- Limpieza de capturas antiguas al iniciar.
- Saneamiento de transformaciones no finitas y rebase de gestos.
- Detección de errores de cámara en tiempo de ejecución.
- Cierre de la cámara en `inactive`, `hidden`, `paused` y `detached`.
- IA de fondo empaquetada y ejecutada on-device, con fallback al procesado por
  color si ONNX no está disponible.
- Límite de 40 MB para imágenes de entrada y 2048 px de textura.
- Limpieza de espacio temporal de capturas y stencils exportados.
- Pruebas de parser PNG y límite de memoria para imágenes maliciosas.

## Privacidad y almacenamiento

- Sin red, sin analytics, sin cuentas.
- El modelo U2-Net y ONNX Runtime están empaquetados en la app; no se descargan
  modelos ni se envían imágenes a ningún servidor.
- Las capturas y los stencils exportados se guardan en el directorio temporal de
  la app.
- Se conservan como máximo las 5 capturas y los 5 stencils más recientes; los
  anteriores se eliminan automáticamente.
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
