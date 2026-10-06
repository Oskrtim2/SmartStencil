using UnityEngine;

namespace ARStencilMapper.Core
{
    public class UserDataManager : MonoBehaviour
    {
        [Header("User Data")]
        public float weight = 70f; // in kg
        public float height = 170f; // in cm
        public float muscleMass = 50f; // arbitrary scale 0-100
        public int age = 25;
        public string gender = "Neutral";

        public void SaveUserData(float newWeight, float newHeight, float newMuscle, int newAge, string newGender)
        {
            weight = newWeight;
            height = newHeight;
            muscleMass = newMuscle;
            age = newAge;
            gender = newGender;

            // In a real scenario, this would save to PlayerPrefs, a local database, or a JSON file
            PlayerPrefs.SetFloat("UserWeight", weight);
            PlayerPrefs.SetFloat("UserHeight", height);
            PlayerPrefs.SetFloat("UserMuscle", muscleMass);
            PlayerPrefs.SetInt("UserAge", age);
            PlayerPrefs.SetString("UserGender", gender);
            PlayerPrefs.Save();
            
            Debug.Log("User data saved successfully.");
        }

        public void LoadUserData()
        {
            weight = PlayerPrefs.GetFloat("UserWeight", 70f);
