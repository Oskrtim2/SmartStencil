using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using ARStencilMapper.Mannequin;

namespace ARStencilMapper.UI
{
    public class ColorPicker : MonoBehaviour, IPointerDownHandler, IDragHandler
    {
        [Header("UI Elements")]
        public RawImage colorWheel;
        
        [Header("References")]
        public SkinColorModifier skinModifier;
        
        private RectTransform rectTransform;

        void Awake()
        {
            if (colorWheel != null)
            {
                rectTransform = colorWheel.GetComponent<RectTransform>();
