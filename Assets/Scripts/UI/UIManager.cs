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
        
        public TextMeshProUGUI weightText;
        public TextMeshProUGUI heightText;
        public TextMeshProUGUI muscleText;

        [Header("References")]
        public UserDataManager userDataManager;
        public MannequinController mannequinController;
        public ARStencilProjector arProjector;

        [Header("Tattoo Designs (Frontend)")]
        public Texture2D[] tattooDesigns;

        public void SelectTattooDesign(int index)
        {
            if (arProjector != null && tattooDesigns != null && index >= 0 && index < tattooDesigns.Length)
            {
                arProjector.SetStencilTexture(tattooDesigns[index]);
            }
        }

        void Start()
        {
            // Setup listeners
            weightSlider.onValueChanged.AddListener(OnWeightChanged);
            heightSlider.onValueChanged.AddListener(OnHeightChanged);
            muscleSlider.onValueChanged.AddListener(OnMuscleChanged);
            
