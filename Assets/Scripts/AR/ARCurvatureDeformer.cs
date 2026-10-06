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
        public float muscleTension = 0.0f;

        private MeshFilter meshFilter;
        private Mesh originalMesh;
        private Mesh deformedMesh;

        void Awake()
        {
            meshFilter = GetComponent<MeshFilter>();
            if (meshFilter != null && meshFilter.sharedMesh != null)
            {
                // Clone the mesh so we don't permanently modify the prefab's mesh
                originalMesh = meshFilter.sharedMesh;
                deformedMesh = Instantiate(originalMesh);
                meshFilter.mesh = deformedMesh;
            }
        }

        void Start()
        {
            ApplyDeformation();
        }

        public void ApplyDeformation()
        {
            if (originalMesh == null || deformedMesh == null) return;

            Vector3[] vertices = originalMesh.vertices;
            Vector3[] newVertices = new Vector3[vertices.Length];

            float safeRadius = Mathf.Max(0.01f, curvatureRadius);

            for (int i = 0; i < vertices.Length; i++)
            {
                Vector3 v = vertices[i];
                
                // Suponemos que el stencil es plano en X-Y y envuelve un cilindro en el eje Y.
                // La distancia 'x' original determina el ángulo de envoltura.
                float angle = v.x / safeRadius;
                
                // Mapeo cilíndrico
                float newX = Mathf.Sin(angle) * safeRadius;
                float newZ = safeRadius - (Mathf.Cos(angle) * safeRadius);

                // Simulador de Tensión Muscular (Abultamiento vertical)
                // Utilizamos una curva parabólica leve basada en el eje Y local
                float verticalFactor = 1.0f - Mathf.Clamp01(Mathf.Pow(v.y * 10f, 2)); // Asumiendo un tamaño de malla razonable
                float bulge = verticalFactor * muscleTension * 0.02f; // Max 2cm de abultamiento muscular
                newZ -= bulge;

                // Aplicar compensación
                newVertices[i] = new Vector3(newX, v.y, newZ);
