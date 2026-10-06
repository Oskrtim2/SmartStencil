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
            
            // Initialize with saved data if needed
            if (userDataManager != null)
            {
                userDataManager.LoadUserData();
                weightSlider.value = userDataManager.weight;
                heightSlider.value = userDataManager.height;
                muscleSlider.value = userDataManager.muscleMass;
            }
        }

        private void OnWeightChanged(float value)
        {
            if (weightText != null) weightText.text = $"Weight: {value:F1} kg";
            UpdateMannequin();
        }

        private void OnHeightChanged(float value)
        {
            if (heightText != null) heightText.text = $"Height: {value:F1} cm";
            UpdateMannequin();
        }

        private void OnMuscleChanged(float value)
        {
            if (muscleText != null) muscleText.text = $"Muscle: {value:F1}";
            UpdateMannequin();
        }

        public void UpdateMannequin()
        {
            if (mannequinController != null)
            {
                mannequinController.UpdateMorph(weightSlider.value, heightSlider.value, muscleSlider.value);
            }
        }

        public void SaveDataBtn()
        {
            if (userDataManager != null)
            {
                userDataManager.SaveUserData(weightSlider.value, heightSlider.value, muscleSlider.value, 25, "Neutral");
            }
        }
    }
}
