# Plan de Implementación: AR Stencil Mapper

## Descripción del Objetivo
Desarrollar una aplicación móvil nativa (APK) orientada al arte corporal (tatuajes y stencils). La aplicación contará con dos características principales:
1. **Proyección AR Avanzada:** Proyección de diseños sobre la piel usando la cámara, con cálculo para compensar la curvatura anatómica y la tensión muscular.
2. **Maniquí 3D Generativo (IA):** Generación de un modelo 3D neutral basado en las características físicas del usuario (peso, altura, edad, sexo, contextura) para visualizar el tatuaje en un entorno 3D antes de la proyección real. Incluirá personalización del color de piel mediante una rueda de colores.

## Estrategia de Arquitectura y Tecnologías

Para cumplir con el requisito de que sea una **aplicación 100% nativa (APK), sin web y orientada a gráficos 3D/AR**, te propongo las siguientes opciones de motor de desarrollo:

### Opción 1: Unity 3D (C#) - **(Altamente Recomendada)**
- **Por qué:** Unity es el estándar de la industria para aplicaciones móviles que requieren Realidad Aumentada robusta y manipulación de modelos 3D en tiempo real. Compila directamente a un archivo APK nativo.
- **Módulo AR:** Uso de *Unity AR Foundation* (que utiliza Google ARCore en Android) para el mapeo de superficies y seguimiento de la topología del cuerpo.
- **Módulo 3D:** Permite integrar modelos paramétricos y manipular materiales (como cambiar el color de piel) de forma nativa y fluida.

### Opción 2: Android Nativo (Kotlin / Java)
- **Por qué:** Es el desarrollo tradicional de Android mediante Android Studio.
- **Módulo AR/3D:** Uso de *Google ARCore* y *Sceneview/Filament* para renderizar 3D.
- **Desventaja:** Manipular mallas 3D y crear un generador de personajes es extremadamente complejo y laborioso en Android puro en comparación con Unity.

## Estrategia de IA para el Maniquí 3D

Dado que la aplicación debe ser autónoma (sin depender de páginas web o apps externas), la mejor manera de implementar la "IA" generadora de cuerpos en un celular es mediante un **Modelo Paramétrico Humano (ej. basado en la tecnología SMPL - Skinned Multi-Person Linear Model)**.

1. **Generación Offline:** La app incluirá una malla 3D base "neutral" (sin ropa o con ropa interior ajustada muy básica).
2. **Transformación:** Cuando el usuario ingrese sus datos (peso, altura, sexo, etc.), un algoritmo matemático interno calculará los "Blendshapes" (deformaciones morfológicas) necesarios para ajustar la malla 3D en tiempo real para que coincida con la contextura descrita, sin necesidad de conectarse a internet.
3. **Color de piel:** Se implementará un *Shader* personalizado conectado a una rueda de colores (Color Picker) que cambiará dinámicamente el color base del modelo 3D.

## Preguntas Abiertas y Decisiones (Requiere tu revisión)

> [!IMPORTANT]
> **1. Elección del Motor de Desarrollo:**
> Confirmado: Utilizaremos **Unity 3D** como base para compilar el APK. Es la herramienta ideal para mezclar AR y modelos 3D complejos en móviles.

> [!TIP]
> **2. Mapeo Anatómico AR y Tensión Muscular (Implementado):**
> Se ha integrado una solución matemática inicial a través del script `ARCurvatureDeformer.cs`. Este componente simula la curvatura cilíndrica del cuerpo (ideal para brazos o piernas) y aplica un ligero cálculo parabólico para emular la tensión o volumen muscular sin depender de sensores complejos de profundidad, utilizando el anclaje de *AR Foundation*.

> [!NOTE]
> **3. UI Funcional y Selección de Color:**
> Se ha incluido el script `ColorPicker.cs` que permite leer los colores directamente desde una imagen (rueda de colores) tocando la pantalla. Esto otorga interactividad completa y personalización en tiempo real del maniquí.

## Cambios Implementados
1. Definir la estructura de carpetas del proyecto (`Assets/Scripts/...`).
2. Crear los scripts iniciales para la interfaz de ingreso de datos del usuario (`UIManager.cs`, `UserDataManager.cs`).
3. Crear el script base del controlador del Maniquí 3D paramétrico (`MannequinController.cs`).
4. Generar el script de la paleta de colores para la piel y su modificador (`ColorPicker.cs`, `SkinColorModifier.cs`).
5. Crear el proyector de texturas AR y el deformador de malla para adaptación a curvaturas (`ARStencilProjector.cs`, `ARCurvatureDeformer.cs`).

## Plan de Verificación
- Compilar el proyecto base en un archivo `.apk` para confirmar que se empaqueta correctamente sin dependencias externas.
- Ejecutar pruebas en un simulador/dispositivo real para verificar que la rueda de colores altera el material del modelo 3D.
