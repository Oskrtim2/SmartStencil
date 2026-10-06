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
                float normalizedY = (localPoint.y - rectTransform.rect.y) / rectTransform.rect.height;

                Texture2D texture = colorWheel.texture as Texture2D;
                if (texture != null)
                {
                    // Clamp to ensure we don't go out of bounds
                    normalizedX = Mathf.Clamp01(normalizedX);
                    normalizedY = Mathf.Clamp01(normalizedY);

                    int texX = Mathf.RoundToInt(normalizedX * texture.width);
                    int texY = Mathf.RoundToInt(normalizedY * texture.height);
                    
                    Color sampledColor = texture.GetPixel(texX, texY);
                    
                    // Ignore transparent pixels (e.g. outside a color wheel circle)
                    if (sampledColor.a > 0.1f)
                    {
                        skinModifier.SetSkinColor(sampledColor);
                    }
                }
            }
        }
    }
}
