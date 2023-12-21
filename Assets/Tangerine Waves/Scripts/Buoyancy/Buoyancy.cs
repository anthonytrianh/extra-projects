using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Buoyancy
{
    public static class Buoyancy
    {
        private static int _WaveA = Shader.PropertyToID("_WaveA");
        private static int _WaveB = Shader.PropertyToID("_WaveB");
        private static int _WaveStrength = Shader.PropertyToID("_WavesStrength");

        static Material LastMat;
        public static Vector4[] Waves;
        static float WaveStrength = 1f;

        public static float SampleWaves(Vector3 position, Material waterMat, float waterLevel, float rollStrength, out Vector3 normal, bool TwoWavesOnly = true)
        {
            Vector3 wavePosition = SampleWaves_Implemmentation(position, waterMat, waterLevel, rollStrength, out normal, TwoWavesOnly);

            return wavePosition.y;
        }

        private static Vector3 SampleWaves_Implemmentation(Vector3 position, Material waterMat, float waterLevel, float rollStrength, out Vector3 normal, bool TwoWavesOnly = true)
        {
            // Invalid material
            if(!waterMat)
            {
                normal = UnityEngine.Vector3.up;
                return new Vector3(0f, waterLevel, 0f);
            }

            if (LastMat == null || LastMat.Equals(waterMat) == false)
            {
                // Get waves
                if (TwoWavesOnly)
                {
                    Waves = new Vector4[2];
                    Waves[0] = waterMat.GetVector(_WaveA);
                    Waves[1] = waterMat.GetVector(_WaveB);
                    WaveStrength = waterMat.GetFloat(_WaveStrength);
                }

                // Assign material
                LastMat = waterMat;
            }

            // Sample

            Vector3 offset = Vector3.zero;
            Vector3 Tangent = new Vector3(1, 0, 0);
            Vector3 Binormal = new Vector3(0, 0, 1);
            Vector3 currentNormal = Vector3.zero;
            float rollFactor = 0;

            // Wave position
            for (int i = 0; i < Waves.Length; i++)
            {
                offset += GerstnerWaves.Gerstner(Waves[i], position, ref Tangent, ref Binormal);
                currentNormal += Vector3.Cross(Binormal, Tangent);
                rollFactor += Mathf.Lerp(0.001f, 0.1f, Waves[i].z);
            }

            rollStrength *= rollFactor;
            currentNormal = new Vector3(currentNormal.x * rollStrength, currentNormal.y, currentNormal.z * rollStrength);

            normal = currentNormal.normalized;
            return offset * WaveStrength;
        }
    }

    public static class GerstnerWaves
    {
        public static Vector3 Gerstner(Vector4 Wave, Vector3 Point, ref Vector3 Tangent, ref Vector3 Binormal)
        {
            float steepness = Wave.z;
            float wavelength = Wave.w;
            float k = 2 * Mathf.PI / wavelength;
            float c = Mathf.Sqrt(9.8f / k);
            float s = Mathf.Max(Mathf.Abs(Wave.x), Mathf.Abs(Wave.y));
            Vector2 d = new Vector2(Wave.x, Wave.y).normalized;
            float f = k * (Vector2.Dot(d, new Vector2(Point.x, Point.z)) - c * Time.time * s);
            float a = steepness / k;

            Tangent += new Vector3(
                -d.x * d.x * (steepness * Mathf.Sin(f)),
                d.x * (steepness * Mathf.Cos(f)),
                -d.x * d.y * (steepness * Mathf.Sin(f))
            );
            Binormal += new Vector3(
                -d.x * d.y * (steepness * Mathf.Sin(f)),
                d.y * (steepness * Mathf.Cos(f)),
                -d.y * d.y * (steepness * Mathf.Sin(f))
            );
            return new Vector3(
                d.x * (a * Mathf.Cos(f)),
                a * Mathf.Sin(f),
                d.y * (a * Mathf.Cos(f))
            );
        }

        //public Vector3 GetWavePosition(Vector3 InPosition, float WaterLevel)
        //{
        //    Vector3 OutPos = new Vector3(InPosition.x, WaterLevel, InPosition.z);
        //    Vector3 Tangent = new Vector3(1, 0, 0);
        //    Vector3 Binormal = new Vector3(0, 0, 1);
        //    for (int i = 0; i < Waves.Length; i++)
        //    {
        //        OutPos += Gerstner(Waves[i], InPosition, ref Tangent, ref Binormal);
        //    }

        //    return OutPos;
        //}
    }
}

