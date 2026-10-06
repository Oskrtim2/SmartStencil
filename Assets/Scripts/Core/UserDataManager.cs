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
