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
