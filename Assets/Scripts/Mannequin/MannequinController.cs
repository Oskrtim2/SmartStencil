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
