using UnityEngine;
using UnityEngine.UI;
using TMPro; // For TextMeshPro
using ARStencilMapper.Core;
using ARStencilMapper.Mannequin;

namespace ARStencilMapper.UI
{
    public class UIManager : MonoBehaviour
    {
        [Header("UI Elements")]
        public Slider weightSlider;
        public Slider heightSlider;
        public Slider muscleSlider;
