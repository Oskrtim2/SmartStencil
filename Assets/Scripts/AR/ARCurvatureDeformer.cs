using UnityEngine;

namespace ARStencilMapper.AR
{
    [RequireComponent(typeof(MeshFilter))]
    public class ARCurvatureDeformer : MonoBehaviour
    {
        [Header("Curvature Settings")]
        [Tooltip("Radio del cilindro imaginario (ej. brazo o pierna) en metros.")]
        public float curvatureRadius = 0.05f; // 5 cm radius by default

        [Tooltip("Tensión muscular simulada (abultamiento).")]
        [Range(0f, 1f)]
