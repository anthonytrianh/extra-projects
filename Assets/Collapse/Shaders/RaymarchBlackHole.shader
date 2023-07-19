Shader "Anthony/Raymarch/BlackHole"
{
    Properties
    {
        [Header(BlackHole)][Space]
        _BlackHoleSize("Black hole size", Range(0, 10)) = 0.3
        _CylinderHalfHeight("Cylinder half height", Range(0, 0.5)) = 0.1
        _CylinderCornerSize ("Cylinder corner size", Range(0, 0.01)) = 0.01
        _HoleEdgeSize ("Ring Size", Range(0, 1)) = 0.05
        _StepSize ("Step Size", Range(0, 0.5)) = 0.005
        _BlackHoleColor("Black hole color", Color) = (0,0,0,1)
        _SchwarzschildRadius("SchwarzschildRadius", Float) = 0.5
        _SpaceDistortion("Space distortion", Float) = 4.069
        _AccretionDiskDistance ("Accretion Disk epsilon", Range(0, 0.1)) = 0.1
        _AccretionDiskColor("Accretion disk color", Color) = (1,1,1,1)
        _AccretionDiskThickness("Accretion disk thickness", Float) = 1
        _DiskNoiseScales("Disk Noise Scales", Vector) = (0.1, 2, 0.6, 0)
        _DiskNoiseExps("Disk Noise Exponents", Vector) = (0.1, 2, 0.6, 0)
        _DiskVolumetricHeight ("Disk Volumetric Height", Float) = 0.5
        _Noise("Accretion disk noise", 2D) = "" {}
        _SkyCube("Skycube", Cube) = "defaulttexture" {}

    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        LOD 100

        Cull Off

        GrabPass
        {
            "_BackgroundTex"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define MAX_STEPS 100
            #define MAX_DIST 150
            #define SURF_DIST 1e-3

            #include "UnityCG.cginc"

            static const float maxFloat = 3.402823466e+38;  

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                // Camera position
                float3 ro : TEXCOORD1;
                // Hit position
                float3 worldPos : TEXCOORD2;
                // Screen position
                float4 screenPos : TEXCOORD3;
                // Object Scale
                float3 objectScale	: TEXCOORD4;
                float3 center		: TEXCOORD5;
            };

            // Global properties
            sampler2D _BackgroundTex;

            // Material properties
            float _BlackHoleSize;
            float _HoleEdgeSize;
            float _CylinderHalfHeight;
            float _CylinderCornerSize;
            float _SchwarzschildRadius;
            float _SpaceDistortion;
            float _StepSize;
            float4 _BlackHoleColor;
            float _AccretionDiskDistance;
            float _AccretionDiskThickness;
            half4 _AccretionDiskColor;
            float4 _DiskNoiseScales;
            float4 _DiskNoiseExps;
            float _DiskVolumetricHeight;
            uniform sampler2D _Noise;
            samplerCUBE _SkyCube;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                // Camera origin 
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)); // world space, fix _WorldSpaceCameraPos into float4 for translation
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); // object space --> need both ro and worldPos to be in the same space

                // Screen pos
                o.screenPos = ComputeScreenPos(o.vertex);

                // Object center and scale
                o.center = UNITY_MATRIX_M._m03_m13_m23;
                o.objectScale = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                    length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                    length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)));

                return o;
            }

            float sdSphere(float3 p, float s)
            {
                return length(p) - s;
            }

            float sdRoundedCylinder(float3 p, float ra, float rb, float h)
            {
                float2 d = float2(length(p.xz) - 2.0 * ra + rb, abs(p.y) - h);
                return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
            }

            float opSmoothSubtraction(float d1, float d2, float k) {
                float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
                return lerp(d2, -d1, h) + k * h * (1.0 - h);
            }

            // A SDF combination creating something that looks like an accretion disk.
            // Made up of a flattened rounded cylinder from which we subtract a sphere.
            float accretionDiskSDF(float3 p, float s, float c) {
                /*float p1 = sdRoundedCylinder(p, s, 0.25, 0.01);
                float p2 = sdSphere(p, s);
                return opSmoothSubtraction(p2, p1, 0.5);*/

                float p1 = sdRoundedCylinder(p, s, _CylinderHalfHeight, _CylinderCornerSize);
                float p2 = sdSphere(p, s);
                return opSmoothSubtraction(p2, p1, c);
            }

            float GetSpaceDistortionLerpValue(float schwarzschildRadius, float distanceToSingularity, float spaceDistortion) {
                return pow(schwarzschildRadius, spaceDistortion) / pow(distanceToSingularity, spaceDistortion);
            }

            float remap(float v, float minOld, float maxOld, float minNew, float maxNew) {
                return minNew + (v - minOld) * (maxNew - minNew) / (maxOld - minOld);
            }

            // Based upon https://viclw17.github.io/2018/07/16/raytracing-ray-sphere-intersection/#:~:text=When%20the%20ray%20and%20sphere,equations%20and%20solving%20for%20t.
            // Returns dstToSphere, dstThroughSphere
            // If inside sphere, dstToSphere will be 0
            // If ray misses sphere, dstToSphere = max float value, dstThroughSphere = 0
            // Given rayDir must be normalized
            float2 intersectSphere(float3 rayOrigin, float3 rayDir, float3 centre, float radius) {

                float3 offset = rayOrigin - centre;
                const float a = 1;
                float b = 2 * dot(offset, rayDir);
                float c = dot(offset, offset) - radius * radius;

                float discriminant = b * b - 4 * a * c;
                // No intersections: discriminant < 0
                // 1 intersection: discriminant == 0
                // 2 intersections: discriminant > 0
                if (discriminant > 0) {
                    float s = sqrt(discriminant);
                    float dstToSphereNear = max(0, (-b - s) / (2 * a));
                    float dstToSphereFar = (-b + s) / (2 * a);

                    if (dstToSphereFar >= 0) {
                        return float2(dstToSphereNear, dstToSphereFar - dstToSphereNear);
                    }
                }
                // Ray did not intersect sphere
                return float2(maxFloat, 0);
            }

            float accretionDiskNoise(float3 p, float distanceToSingularity, float diskSize, float noiseScale, float rotationSpeed, float noisePow, float thickness, float holeSize)
            {
                float ret = 0;

                float epsilon = 0.01;
                float sdfResult = accretionDiskSDF(p, diskSize, holeSize);
                // Accretion disk light
                // Inside the acceration disk. Sample light.
                if (sdfResult < epsilon)
                {
                    // Shit UV generation apparently
                    // Polar coordinates
                    // Rotate the texture sampling to fake motion.
                    float u = cos(_Time.z * rotationSpeed - (distanceToSingularity));
                    float v = sin(_Time.z * rotationSpeed - (distanceToSingularity));
                    float2x2 rot = float2x2(u, -v, v, u);
                    float2 uv = mul(rot, p.xz * noiseScale);

                    // Get thickness from the noise texture.
                    float noise = pow(tex2D(_Noise, uv).r, noisePow);
                    float t = noise * thickness;

                    ret += noise;
                }

                return ret;
            }

            float4 accretionDisks(float3 p, float distanceToSingularity) 
            {
                float4 finalColor = 0;

                // Calculate noise for disks
                float finalNoise = 0;

                // Disk 1
                float disk1 = accretionDiskNoise(p, distanceToSingularity, _BlackHoleSize, _DiskNoiseScales.x, -0.5, _DiskNoiseExps.x, 0.25, _HoleEdgeSize);
                float disk2 = accretionDiskNoise(p, distanceToSingularity, _BlackHoleSize, _DiskNoiseScales.y, -2.75, _DiskNoiseExps.y, 0.5, _HoleEdgeSize);
                float disk3 = accretionDiskNoise(p, distanceToSingularity, _BlackHoleSize * 0.65, _DiskNoiseScales.z, -2, _DiskNoiseExps.z, 0.8, _HoleEdgeSize * 3);

                finalNoise = saturate(disk1 + disk2 + disk3);

                finalColor = finalNoise * _AccretionDiskColor;
                return finalColor;
            }

            // Returns a distance to the scene
            // In: ray origin, ray direction
            float4 raymarch(float3 ro, float3 rd, v2f i)
            {
                // Ray information
                const int maxsteps = 665;
                float3 currentPos = ro;
                float3 currentRayDir = rd;
                float stepSize = _StepSize;
                float3 blackHolePosition = float3(0, 0, 0);
                float distanceToSingularity = 99999999;
                float accretionDiskEpsilon = 0.01;
                float blackHoleInfluence = 0;
                float distortion = 0;
                half rotationSpeed = -1.5;
                float thickness = 0;
                half4 lightAccumulation = half4(0, 0, 0, 1);
                float2 screenUV = i.screenPos.xy / i.screenPos.w;

                // Outer sphere bounds
                float sphereRadius = 0.45 * min(min(i.objectScale.x, i.objectScale.y), i.objectScale.z);
                float2 outerSphereIntersection = intersectSphere(ro, rd, i.center, sphereRadius);

                // Raymarching loop (for number of maximum steps/times)
                for (int i = 0; i < maxsteps; i++)
                {
                    // Get two vectors. One pointing in previous direction and one pointing to the singularity. 
                    float3 unaffectedDir = normalize(currentRayDir) * stepSize;
                    float3 maxAffectedDir = normalize(blackHolePosition - currentPos) * stepSize;
                    distanceToSingularity = distance(blackHolePosition, currentPos);

                    // Calculate how to interpolate between the two previously calculated vectors.
                    float lerpValue = GetSpaceDistortionLerpValue(_SchwarzschildRadius, distanceToSingularity, _SpaceDistortion);
                    float3 newRayDir = normalize(lerp(unaffectedDir, maxAffectedDir, lerpValue)) * stepSize;

                    // Move the lightray along and calculate the sdf result
                    float3 newPos = currentPos + newRayDir;

                    // Calculate disks
                    lightAccumulation += accretionDisks(newPos, distanceToSingularity);

                    // Calculate black hole influence on the final color.
                    blackHoleInfluence = smoothstep(_SchwarzschildRadius + 0.1, _SchwarzschildRadius - 0.1, distanceToSingularity);
                    currentPos = newPos;
                    currentRayDir = newRayDir;
                }

                // Scene color distortion
                float3 distortedRayDir = normalize(currentPos - ro);
                //distortedRayDir = mul(unity_WorldToObject, float4(distortedRayDir, 1));
                float4 rayCameraSpace = mul(unity_WorldToCamera, float4(distortedRayDir, 0));
                float4 rayUVProj = mul(unity_CameraProjection, float4(rayCameraSpace));
                float2 distortedScreenUV = rayUVProj.xy + 1 * 0.5;

                // Screen and object edge transitions
                float edgeFadex = smoothstep(0, 0.25, 1 - abs(remap(screenUV.x, 0, 1, -1, 1)));
                float edgeFadey = smoothstep(0, 0.25, 1 - abs(remap(screenUV.y, 0, 1, -1, 1)));
                float t = saturate(remap(outerSphereIntersection.y, sphereRadius, 2 * sphereRadius, 0, 1)) * edgeFadex * edgeFadey;
                distortedScreenUV = lerp(screenUV, distortedScreenUV, t);

                float3 backgroundColor = tex2D(_BackgroundTex, distortedScreenUV).rgb;

                // Sample let background be either skybox or the black hole color.
                half4 background = lerp(float4(backgroundColor.rgb, 0), _BlackHoleColor, blackHoleInfluence);
                // Volumetric?
                lightAccumulation *= pow(abs(ro.y) / _DiskVolumetricHeight, 0.5);

                return background + lightAccumulation;
            }

            //// Calculate normal for raymarched point
            //float3 GetNormal(float3 p)
            //{
            //    float2 e = float2(1e-2, 0);
            //    float3 n = GetDist(p) - float3(
            //        GetDist(p - e.xyy),
            //        GetDist(p - e.yxy),
            //        GetDist(p - e.yyx)
            //        );
            //    return normalize(n);
            //}

            fixed4 frag(v2f i) : SV_Target
            {
                // Raymarching Begin
                // - Start with a virtual camera
                float3 ro = _WorldSpaceCameraPos; // ro: Ray Origin, Camera position
                float3 rd = normalize(i.worldPos - ro); // rd: Ray Direction, actual viewing ray that shoots out of camera

                return raymarch(ro, rd, i);
            }
            ENDCG
        }
    }
}
