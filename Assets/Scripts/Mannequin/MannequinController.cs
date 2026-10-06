using UnityEngine;

namespace ARStencilMapper.Mannequin
{
    public class MannequinController : MonoBehaviour
    {
        [Header("Mannequin Settings")]
        public Renderer mannequinMesh;
        
        // Example Blendshapes indexes (these will depend on the specific 3D model used)
        private int weightBlendshapeIndex = 0;
        private int heightBlendshapeIndex = 1;
        private int muscleBlendshapeIndex = 2;

        public void UpdateMorph(float weight, float height, float muscleMass)
        {
            if (mannequinMesh == null)
            {
                Debug.LogWarning("Mannequin Mesh is not assigned.");
                return;
            }

            SkinnedMeshRenderer skinnedMesh = mannequinMesh as SkinnedMeshRenderer;

            if (skinnedMesh != null && skinnedMesh.sharedMesh.blendShapeCount > 0)
            {
                // Si tiene esqueleto y Blendshapes:
                float weightValue = Mathf.Clamp(weight * 0.5f, 0, 100); 
                float heightValue = Mathf.Clamp(height * 0.5f, 0, 100);
                float muscleValue = Mathf.Clamp(muscleMass * 0.5f, 0, 100);

                if (skinnedMesh.sharedMesh.blendShapeCount > weightBlendshapeIndex) skinnedMesh.SetBlendShapeWeight(weightBlendshapeIndex, weightValue);
                if (skinnedMesh.sharedMesh.blendShapeCount > heightBlendshapeIndex) skinnedMesh.SetBlendShapeWeight(heightBlendshapeIndex, heightValue);
                if (skinnedMesh.sharedMesh.blendShapeCount > muscleBlendshapeIndex) skinnedMesh.SetBlendShapeWeight(muscleBlendshapeIndex, muscleValue);
            }
            else
            {
                // FALLBACK PARA MODELOS ESTÁTICOS (Sin esqueleto / T-Pose)
                // Usamos la escala local (Transform.localScale)
                // Altura base: 170cm = escala 1 en Y
