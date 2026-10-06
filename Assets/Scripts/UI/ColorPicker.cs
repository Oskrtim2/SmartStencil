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
            }
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            PickColor(eventData);
        }

        public void OnDrag(PointerEventData eventData)
        {
            PickColor(eventData);
        }

        private void PickColor(PointerEventData eventData)
        {
            if (rectTransform == null || skinModifier == null) return;

            Vector2 localPoint;
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(rectTransform, eventData.position, eventData.pressEventCamera, out localPoint))
            {
                // Normalize coordinates (0 to 1) based on the image size
                float normalizedX = (localPoint.x - rectTransform.rect.x) / rectTransform.rect.width;
