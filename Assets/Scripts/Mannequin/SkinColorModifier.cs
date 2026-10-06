using UnityEngine;

namespace ARStencilMapper.Mannequin
{
    public class SkinColorModifier : MonoBehaviour
    {
        [Header("Skin Material Settings")]
        public Renderer mannequinMesh;
        public int materialIndex = 0;
        public string colorPropertyName = "_BaseColor"; // Common for URP/HDRP, or "_Color" for Standard

        public void SetSkinColor(Color newColor)
        {
            if (mannequinMesh == null || mannequinMesh.materials.Length <= materialIndex)
            {
                Debug.LogWarning("Mannequin Mesh or Material is not correctly assigned.");
                return;
            }

            // Update the material color
            Material skinMaterial = mannequinMesh.materials[materialIndex];
            if (skinMaterial.HasProperty(colorPropertyName))
            {
                skinMaterial.SetColor(colorPropertyName, newColor);
            }
            else
            {
                Debug.LogWarning($"Property {colorPropertyName} not found on the material.");
            }
        }
    }
}
