using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Buoyancy
{
    [ExecuteInEditMode]
    public class FloatingTransform : MonoBehaviour
    {
        // Water
        public WaterObject Water;

        public float WaterLevel;
        private float m_WaterLevel = 0f;

        private Vector3 normal;
        private float height;

        public float HeightOffset;
        [Min(0)]
        [Tooltip("Controls how strongly the transform should rotate to align with the wave curvature")]
        public float RollAmount = 0.1f;

        [Header("Experimental")]
        public float MoveAmount = 0f;

        // Sample points
        public List<Transform> SamplePoints = new List<Transform>();


        // Start is called before the first frame update
        void Start()
        {
        
        }

#if UNITY_EDITOR
        private void OnEnable()
        {
            UnityEditor.EditorApplication.update += FixedUpdate;
        }
        private void OnDisable()
        {
            UnityEditor.EditorApplication.update -= FixedUpdate;
        }
#endif

        public void FixedUpdate()
        {
            if (!this || !this.enabled) return;

            #if UNITY_EDITOR
                if (Application.isPlaying == false) return;
            #endif

            if (!Water || !Water.material) return;

            m_WaterLevel = Water ? Water.transform.position.y : WaterLevel;

            // Buoyancy transforms
            normal = Vector3.up;
            height = 0f;

            // Use object's pivot
            if (SamplePoints.Count == 0)
            {
                height = Buoyancy.SampleWaves(this.transform.position, Water.material, m_WaterLevel, RollAmount, out normal);

                // Movement
                if (MoveAmount != 0)
                {
                    // Displace on the X and Z axes
                    transform.position += new Vector3(normal.x, 0, normal.z) * MoveAmount;
                    // Resample new wave offset
                    height = Buoyancy.SampleWaves(this.transform.position, Water.material, m_WaterLevel, RollAmount, out normal);
                }

            }
            // Otherwise use weighted points

            // Base offset
            height += HeightOffset;

            ApplyTransform();
        }

        void ApplyTransform()
        {
            if(RollAmount > 0) this.transform.up = normal;
            this.transform.position = new Vector3(this.transform.position.x, height, this.transform.position.z);
        }
    }
}

