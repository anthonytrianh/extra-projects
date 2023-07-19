using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Buoyancy
{
    public class WaterObject : MonoBehaviour
    {
        public Material material;
        public MeshFilter meshFilter;
        public MeshRenderer meshRenderer;

        private void OnEnable()
        {
        }

        private void OnDisable()
        {
        }

        private void OnValidate()
        {
            if (!meshRenderer) meshRenderer = GetComponent<MeshRenderer>();
            if (!meshFilter) meshFilter = GetComponent<MeshFilter>();
            FetchWaterMaterial();
        }

        public void FetchWaterMaterial()
        {
            if (meshRenderer) material = meshRenderer.sharedMaterial;
        }
    }

}
