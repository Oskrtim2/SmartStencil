# SmartStencil

[![Flutter CI](https://github.com/Oskrtim2/SmartStencil/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/Oskrtim2/SmartStencil/actions/workflows/flutter-ci.yml)

Aplicación Flutter **100 % offline** para probar tatuajes en tiempo real con la
cámara del dispositivo.

- Proyecto: [`tattoo_ar_preview/`](tattoo_ar_preview/)
- Plataformas: Android e iOS.
- Sin backend, base de datos, autenticación ni internet.
- Importa cualquier imagen y la convierte en un stencil transparente.
- IA U2-Net empaquetada para eliminar fondos complejos sin conexión.
- Exporta el stencil como PNG transparente.
- Tinta realista con shader GLSL y `BlendMode.multiply`.
- Gestos multitáctiles, intensidad de tinta y captura con share sheet nativo.

## Inicio rápido

```bash
cd tattoo_ar_preview
flutter pub get
flutter run
```

Compilar APK debug:

```bash
flutter build apk --debug
```

La documentación completa de arquitectura, permisos, pipeline gráfico y pruebas
está en [`tattoo_ar_preview/README.md`](tattoo_ar_preview/README.md).
