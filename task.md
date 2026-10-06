# Tareas del Proyecto: AR Stencil Mapper

- [x] **Fase 1: Inicialización**
  - [x] Crear estructura de directorios para los scripts
  - [x] Proveer instrucciones claras para que el usuario importe los scripts en Unity Hub
- [x] **Fase 2: Generador del Maniquí 3D Paramétrico (IA Offline)**
  - [x] Crear script `MannequinController.cs` (Manejo de Morph Targets / Blendshapes según altura, peso, etc.)
  - [x] Crear script `SkinColorModifier.cs` (Control del Shader para cambiar el color de piel)
  - [x] Crear script `UserDataManager.cs` (Almacenamiento y cálculo de la complexión)
- [x] **Fase 3: Motor de Proyección AR**
  - [x] Crear script `ARStencilProjector.cs` (Proyección de texturas y adaptación a superficies curvas usando AR Foundation)
- [x] **Fase 4: Interfaz de Usuario (UI)**
  - [x] Crear script `UIManager.cs` (Control de sliders, campos de texto y paleta de colores)
- [x] **Fase 5: Funcionalidades Avanzadas**
  - [x] Crear script `ColorPicker.cs` (Lógica de selección de color en la UI para la piel)
  - [x] Crear script `ARCurvatureDeformer.cs` (Deformación de malla para simular curvatura anatómica y tensión)
  - [x] Actualizar `ARStencilProjector.cs` para utilizar el deformador de malla tras el Raycast
- [x] **Fase 6: Configuración Visual en Unity (Tutorial)**
  - [x] Crear el plan y tutorial paso a paso para la jerarquía del Canvas UI.
  - [x] Diseñar el flujo para enlazar los scripts en Unity 2023+.
