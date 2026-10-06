# Instrucciones de Integración para Unity

Sigue estos pasos para importar y configurar los scripts generados en tu proyecto de Unity.

## 1. Crear el Proyecto en Unity Hub
1. Abre **Unity Hub**.
2. Haz clic en **New project**.
3. Selecciona la plantilla **AR (Mobile Core)** o **3D (URP)** (Universal Render Pipeline es altamente recomendado para un buen balance entre rendimiento en móviles y calidad visual).
4. Nombra tu proyecto (ej. `ARStencilMapper`) y haz clic en **Create project**.

## 2. Importar los Scripts
1. En el proyecto de Unity, ve a la ventana **Project** (generalmente en la parte inferior).
2. Localiza la carpeta `Assets`.
3. Haz clic derecho y selecciona **Create > Folder**, y nómbrala `Scripts`.
4. Arrastra las carpetas `Mannequin`, `Core`, `AR` y `UI` que hemos generado, y pégalas dentro de la carpeta `Assets/Scripts/` en el explorador de tu computadora.
5. Regresa a Unity. El editor automáticamente compilará los nuevos scripts.

## 3. Configuración Adicional de AR Foundation
Si no elegiste la plantilla AR, necesitas instalar los paquetes manualmente:
1. Ve a **Window > Package Manager**.
2. Selecciona **Packages: Unity Registry**.
3. Busca e instala:
   - `AR Foundation`
   - `Google ARCore XR Plugin` (para Android)
   - `Apple ARKit XR Plugin` (si también planeas exportar a iOS)

## 4. Configurar la Escena AR
1. En tu escena, elimina la `Main Camera` predeterminada.
2. Haz clic derecho en la jerarquía y selecciona **XR > AR Session** y luego **XR > AR Session Origin**.
3. Agrega el script `ARStencilProjector.cs` al **AR Session Origin**.
4. Agrega un componente **AR Raycast Manager** al mismo objeto (si no se añadió automáticamente).

## 5. Configurar el Maniquí y UI
1. Crea un GameObject vacío en la escena llamado `AppManager` y añádele el script `UserDataManager.cs`.
2. Para el maniquí, importa tu modelo 3D con *Blendshapes*, arrástralo a la escena, y añádele `MannequinController.cs` y `SkinColorModifier.cs`. Asigna el *Skinned Mesh Renderer* de tu modelo 3D en el inspector a estos scripts.
3. Para la UI, crea un Canvas (`GameObject > UI > Canvas`) y diseña tus sliders. Añade el script `UIManager.cs` a un objeto (puede ser en el mismo Canvas) y enlaza los sliders y los otros scripts (`UserDataManager` y `MannequinController`) arrastrándolos desde la Jerarquía hacia los campos correspondientes en el Inspector de Unity.
