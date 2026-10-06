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
