using UnityEngine;

namespace ARStencilMapper.Mannequin
{
    public class SkinColorModifier : MonoBehaviour
    {
        [Header("Skin Material Settings")]
        public Renderer mannequinMesh;
        public int materialIndex = 0;
        public string colorPropertyName = "_BaseColor"; // Common for URP/HDRP, or "_Color" for Standard
