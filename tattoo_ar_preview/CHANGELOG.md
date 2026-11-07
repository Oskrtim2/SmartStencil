# Changelog

Todas las modificaciones relevantes de SmartStencil se documentan aquí.

## Unreleased

### Added

- Recuperación de selecciones de galería perdidas tras la recreación de la
  actividad Android.
- Reinicio del diseño con doble toque.
- Anuncio accesible del progreso de captura con regiones vivas.
- Localización de los widgets Material integrados en español.
- Pantalla de error amigable en builds release.
- Flujo de CI con formato, análisis, pruebas y build de APK debug.
- Pruebas de permisos de cámara, guard de captura, nombres de archivo,
  geometría del shader, resultados de captura y controles de tinta.

### Fixed

- Los controles inferiores no se reconstruían cuando la cámara terminaba de
  inicializarse, dejando la vista previa sin panel de tinta.
- Zonas muertas del pellizco al alcanzar los límites de escala.
- Saltos de transformación al añadir o retirar dedos, al terminar un gesto o al
  cambiar el viewport.
- Valores NaN o infinitos en la transformación.
- Errores de cámara en tiempo de ejecución y bloqueos al inicializar.
- Inicializaciones concurrentes y ausencia de timeout al abrir la cámara.
- Fugas de textura al desmontar el editor durante una captura.
- Condiciones de carrera y capturas concurrentes.
- Colisiones de nombres de archivo temporales.
- Escrituras incompletas y fallos de almacenamiento al capturar.
- Mensajes de error técnicos expuestos al usuario.
- Fugas de memoria y PNGs con dimensiones o tipos de color no válidos.
- Archivos PNG sin transparencia real.
- Desbordes de la interfaz con texto grande y objetivos táctiles pequeños.
- Falta de timeout al cargar el shader.
- Falta de manejo de errores asíncronos no controlados.

### Changed

- Los límites, tiempos y valores por defecto están centralizados.
- Los uniforms del shader se configuran por nombre.
- Se omite la máscara del shader cuando la tinta está al 0 %.
- Se podan las capturas antiguas al iniciar.
- Se habilitaron modos estrictos del analizador y lints adicionales.
