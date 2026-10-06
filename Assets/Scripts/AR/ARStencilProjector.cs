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
