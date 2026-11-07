# SmartStencil

Aplicación Flutter **100 % offline** para probar tatuajes en tiempo real con la
cámara del dispositivo.

- Proyecto: [`tattoo_ar_preview/`](tattoo_ar_preview/)
- Plataformas: Android e iOS.
- Sin backend, base de datos, autenticación ni internet.
- Tinta realista con shader GLSL y `BlendMode.multiply`.
- Importación de PNG transparentes, gestos multitáctiles, intensidad de tinta y
  captura con share sheet nativo.

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
