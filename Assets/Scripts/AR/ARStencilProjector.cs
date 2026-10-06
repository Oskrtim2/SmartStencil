using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using System.Collections.Generic;

namespace ARStencilMapper.AR
{
    [RequireComponent(typeof(ARRaycastManager))]
    public class ARStencilProjector : MonoBehaviour
    {
        private ARRaycastManager arRaycastManager;
        private List<ARRaycastHit> hits = new List<ARRaycastHit>();

        [Header("Projection Settings")]
        public GameObject stencilPrefab;
        private GameObject spawnedStencil;

        [Header("Tattoo Material Settings")]
        public Material stencilMaterial; // El material que usa el stencilPrefab

        public void SetStencilTexture(Texture2D newTexture)
        {
            if (stencilMaterial != null)
            {
                // Soporte para URP ("_BaseMap") o Standard ("_MainTex")
                if (stencilMaterial.HasProperty("_BaseMap"))
                    stencilMaterial.SetTexture("_BaseMap", newTexture);
                else if (stencilMaterial.HasProperty("_MainTex"))
                    stencilMaterial.SetTexture("_MainTex", newTexture);
            }
            else
            {
                Debug.LogWarning("Stencil Material is not assigned in the AR Projector.");
            }
        }

        void Awake()
        {
            arRaycastManager = GetComponent<ARRaycastManager>();
        }

        void Update()
        {
            if (Input.touchCount > 0)
            {
                Touch touch = Input.GetTouch(0);

                if (touch.phase == TouchPhase.Began)
                {
                    // Perform a raycast against AR planes and point clouds
                    if (arRaycastManager.Raycast(touch.position, hits, TrackableType.PlaneWithinPolygon | TrackableType.FeaturePoint))
                    {
                        Pose hitPose = hits[0].pose;

                        if (spawnedStencil == null)
                        {
                            spawnedStencil = Instantiate(stencilPrefab, hitPose.position, hitPose.rotation);
                        }
                        else
                        {
                            spawnedStencil.transform.position = hitPose.position;
                            spawnedStencil.transform.rotation = hitPose.rotation;
                        }

                        // Fase 5: Ajuste del stencil a la curvatura cilíndrica/muscular
                        AdaptStencilToCurvature(spawnedStencil);
                    }
                }
            }
        }

        private void AdaptStencilToCurvature(GameObject stencil)
        {
            // Busca si el stencil tiene el componente de deformación
            ARCurvatureDeformer deformer = stencil.GetComponent<ARCurvatureDeformer>();
