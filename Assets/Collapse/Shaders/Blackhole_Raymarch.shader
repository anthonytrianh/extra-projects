// Based on tutorial by: https://kelvinvanhoorn.com/2021/04/20/supermassive-black-hole-tutorial
Shader "Anthony/Space/Blackhole_Raymarch"
{
    Properties
    {
        [Header(AccretionDisk)][Space]
        _DiskWidth ("Accretion disk width", Float) = 0.1
        _DiskOuterRadius ("Accretion disk outer radius", Range(0, 1)) = 1
        _DiskInnerRadius("Accretion disk inner radius", Range(0, 1)) = 0.2

        [Header(DiskNoise)][Space]
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseSpeed ("Noise Speed", Float) = 1.25
        _SecondaryNoiseTex ("Secondary Noise Texture", 2D) = "white" {}
        _SecondaryNoiseSpeed ("Secondary Speed", Float) = 2
        _SecondaryNoiseCutoff ("Secondary Noise Cutoff", Range(0, 1)) = 0.2
        _SecondaryNoiseSmoothness("Secondary Noise Smoothness", Range(0, 1)) = 0.05


        [Header(DiskColor)][Space]
        [HDR] _DiskColor ("Disk color", Color) = (0, 1, 1, 1)
        _DopplerBeamingFactor ("Doppler beaming factor", Float) = 66
        _HueRadius ("Hue shift start radius", Range(0, 1)) = 0.75
        _HueShiftFactor ("Hue shift factor", Float) = -0.03
        _CenterHeatIntensity ("Center heat intensity", Float) = 1
        _CenterHeatMin ("Center heat min", Range(0, 1)) = 0
        _CenterHeatMax ("Center heat max", Range(0, 5)) = 1

        [Header(Blackhole)][Space]
        _Steps("Raymarch steps", Int) = 256
        _StepSize("Step size", Range(0.001, 1)) = 0.1
        // Radius that defines the event horizon of a Schwarzschild black hole
        _SchwarzschildRadius ("Schwarzschild radius", Range(0, 1)) = 0.2
        _Gravity ("Gravitation constant", Float) = 0.15
        _GravityAdjust ("Gravity Adjustments, Pow (X) Offset (Y)", Vector) = (1, 0, 0, 0)
    }

    CGINCLUDE
    #include "UnityCG.cginc"
    #define MAX_DIST 3.402823466e+38

    // Structs
    struct appdata
    {
        float4 vertex : POSITION;
    };

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float3 worldPos: TEXCOORD0;

        float3 center : TEXCOORD1;
        float3 objectScale : TEXCOORD2;

        float4 screenPos : TEXCOORD3;
    };


    // Global properties
    uniform sampler2D _BackgroundTex;

    // Material properties
    float _DiskWidth;
    float _DiskOuterRadius;
    float _DiskInnerRadius;

    sampler2D _NoiseTex;
    float4 _NoiseTex_ST;
    float _NoiseSpeed;
    sampler2D _SecondaryNoiseTex;
    float4 _SecondaryNoiseTex_ST;
    float _SecondaryNoiseSpeed;
    float _SecondaryNoiseCutoff;
    float _SecondaryNoiseSmoothness;

    float4 _DiskColor;
    float _DopplerBeamingFactor;
    float _HueRadius;
    float _HueShiftFactor;

    float _CenterHeatIntensity;
    float _CenterHeatMin;
    float _CenterHeatMax;

    int _Steps;
    float _StepSize;
    float _SchwarzschildRadius;
    float _Gravity;
    float4 _GravityAdjust;

    /////////////////////////////////
    // Helper functions
    // 1. Sphere Intersect
    // Based upon https://viclw17.github.io/2018/07/16/raytracing-ray-sphere-intersection
    // Returns dstToSphere, dstThroughSphere
    // If inside sphere, dstToSphere will be 0
    // If ray misses sphere, dstToSphere = max float value, dstThroughSphere = 0
    // Given rayDir must be normalized
    float2 intersectSphere(float3 rayOrigin, float3 rayDir, float3 center, float radius) {

        float3 offset = rayOrigin - center;
        const float a = 1;
        float b = 2 * dot(offset, rayDir);
        float c = dot(offset, offset) - radius * radius;

        float discriminant = b * b - 4 * a * c;
        // No intersections: discriminant < 0
        // 1 intersection: discriminant == 0
        // 2 intersections: discriminant > 0
        if (discriminant > 0)
        {
            float s = sqrt(discriminant);
            float dstToSphereNear = max(0, (-b - s) / (2 * a));
            float dstToSphereFar = (-b + s) / (2 * a);

            if (dstToSphereFar >= 0)
            {
                return float2(dstToSphereNear, dstToSphereFar - dstToSphereNear);
            }
        }
        // Ray did not intersect sphere
        return float2(MAX_DIST, 0);
    }

    // 2. Raytrace disk
    // 2.1 Intersect infinite cylinder
    // Based upon https://mrl.cs.nyu.edu/~dzorin/rend05/lecture2.pdf
    float2 intersectInfiniteCylinder(float3 rayOrigin, float3 rayDir, float3 cylinderOrigin, float3 cylinderDir, float cylinderRadius)
    {
        // A = (v - (v, va)va)^2
        float3 a0 = rayDir - dot(rayDir, cylinderDir) * cylinderDir;
        float a = dot(a0, a0);

        float3 dP = rayOrigin - cylinderOrigin;
        // C = (dp - (dp va)va)^2 - r^2
        float3 c0 = dP - dot(dP, cylinderDir) * cylinderDir;
        float c = dot(c0, c0) - cylinderRadius * cylinderRadius;

        // B = 2(a,c)
        float b = 2 * dot(a0, c0);

        float discriminant = b * b - 4 * a * c;

        if (discriminant > 0)
        {
            float s = sqrt(discriminant);
            float dstToNear = max(0, (-b - s) / (2 * a));
            float dstToFar = (-b + s) / (2 * a);

            if (dstToFar >= 0)
            {
                return float2(dstToNear, dstToFar - dstToNear);
            }
        }
        return float2(MAX_DIST, 0);
    }

    // 2.2 Intersect infinite plane
    // Based upon https://mrl.cs.nyu.edu/~dzorin/rend05/lecture2.pdf
    float intersectInfinitePlane(float3 rayOrigin, float3 rayDir, float3 planeOrigin, float3 planeDir)
    {
        float a = 0;
        float b = dot(rayDir, planeDir);
        float c = dot(rayOrigin, planeDir) - dot(planeDir, planeOrigin);

        float discriminant = b * b - 4 * a * c;

        return -c / b;
    }

    // 2.3 Intersect disc/disk SDF
    // Based upon https://mrl.cs.nyu.edu/~dzorin/rend05/lecture2.pdf
    float intersectDisk(float3 rayOrigin, float3 rayDir, float3 p1, float3 p2, float3 discDir, float discRadius, float innerRadius)
    {
        float discDst = MAX_DIST;
        float2 cylinderIntersection = intersectInfiniteCylinder(rayOrigin, rayDir, p1, discDir, discRadius);
        float cylinderDst = cylinderIntersection.x;

        if (cylinderDst < MAX_DIST)
        {
            float finiteC1 = dot(discDir, rayOrigin + rayDir * cylinderDst - p1);
            float finiteC2 = dot(discDir, rayOrigin + rayDir * cylinderDst - p2);

            // Ray intersects with edges of the cylinder/disc
            if (finiteC1 > 0 && finiteC2 < 0 && cylinderDst > 0)
            {
                discDst = cylinderDst;
            }
            else
            {
                float radiusSqr = discRadius * discRadius;
                float innerRadiusSqr = innerRadius * innerRadius;

                float p1Dst = max(intersectInfinitePlane(rayOrigin, rayDir, p1, discDir), 0);
                float3 q1 = rayOrigin + rayDir * p1Dst;
                float p1q1DstSqr = dot(q1 - p1, q1 - p1);

                // Ray intersects with lower plane of cylinder/disc
                if (p1Dst > 0 && p1q1DstSqr < radiusSqr && p1q1DstSqr > innerRadiusSqr)
                {
                    if (p1Dst < discDst)
                    {
                        discDst = p1Dst;
                    }
                }

                float p2Dst = max(intersectInfinitePlane(rayOrigin, rayDir, p2, discDir), 0);
                float3 q2 = rayOrigin + rayDir * p2Dst;
                float p2q2DstSqr = dot(q2 - p2, q2 - p2);

                // Ray intersects with upper plane of cylinder/disc
                if (p2Dst > 0 && p2q2DstSqr < radiusSqr && p2q2DstSqr > innerRadiusSqr)
                {
                    if (p2Dst < discDst)
                    {
                        discDst = p2Dst;
                    }
                }
            }
        }

        return discDst;
    }

    float remap(float v, float minOld, float maxOld, float minNew, float maxNew) 
    {
        return minNew + (v - minOld) * (maxNew - minNew) / (maxOld - minOld);
    }

    // Calculate disk uv using polar coordinates
    float2 diskUV(float3 planarDiscPos, float3 discDir, float3 centre, float radius)
    {
        // How much is the direction to this point pointing away from the center
        float3 planarDiscPosNorm = normalize(planarDiscPos);
        // Remap to (0, 1)
        float sampleDist01 = length(planarDiscPos) / radius;

        float3 tangentTestVector = float3(1, 0, 0);
        // If disk is oriented sideways, swap tangent vector
        if (abs(dot(discDir, tangentTestVector)) >= 1)
            tangentTestVector = float3(0, 1, 0);

        float3 tangent = normalize(cross(discDir, tangentTestVector));
        float3 biTangent = cross(tangent, discDir);
        // Calculate radial angle
        float phi = atan2(dot(planarDiscPosNorm, tangent), dot(planarDiscPosNorm, biTangent)) / UNITY_PI;
        phi = remap(phi, -1, 1, 0, 1);

        // Radial distance
        float u = sampleDist01;
        // Angular distance
        float v = phi;

        return float2(u, v);
    }

    // Based upon UnityCG.cginc, used in hdrIntensity 
    float3 LinearToGammaSpace(float3 linRGB)
    {
        linRGB = max(linRGB, float3(0.f, 0.f, 0.f));
        // An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
        return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);
    }

    // Based upon UnityCG.cginc, used in hdrIntensity 
    float3 GammaToLinearSpace(float3 sRGB)
    {
        // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
        return sRGB * (sRGB * (sRGB * 0.305306011f + 0.682171111f) + 0.012522878f);
    }

    // Based upon https://forum.unity.com/threads/how-to-change-hdr-colors-intensity-via-shader.531861/
    float3 hdrIntensity(float3 emissiveColor, float intensity)
    {
        // if not using gamma color space, convert from linear to gamma
#ifndef UNITY_COLORSPACE_GAMMA
        emissiveColor.rgb = LinearToGammaSpace(emissiveColor.rgb);
#endif
        // apply intensity exposure
        emissiveColor.rgb *= pow(2.0, intensity);
        // if not using gamma color space, convert back to linear
#ifndef UNITY_COLORSPACE_GAMMA
        emissiveColor.rgb = GammaToLinearSpace(emissiveColor.rgb);
#endif

        return emissiveColor;
    }

    // Based upon Unity's shadergraph library functions
    float3 RGBToHSV(float3 c)
    {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    // Based upon Unity's shadergraph library functions
    float3 HSVToRGB(float3 c)
    {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
    }

    // Based upon Unity's shadergraph library functions
    float3 RotateAboutAxis(float3 In, float3 Axis, float Rotation)
    {
        float s = sin(Rotation);
        float c = cos(Rotation);
        float one_minus_c = 1.0 - c;

        Axis = normalize(Axis);
        float3x3 rot_mat =
        { one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
            one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
            one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
        };
        return mul(rot_mat, In);
    }

    // Disk color function
    //  Changes the disk color in 3 ways:
    //  - Increases the intensity at the center and gradually decrease over radial distance
    //  - Doppler beaming effect: parts that move towards the camera have higher intensity than parts that move away from the camera
    //  - Shift hue over radial distance from a starting radius
    float3 diskColor(float3 baseColor, float3 diskPos, float3 diskDir, float3 cameraPos, float u, float radius, float falloff) 
    {
        float3 color = baseColor;

        // 1. Distance intensity falloff
        float intensity = remap(u, 0, 1, 0.5, -1.2);
        intensity *= abs(intensity);

        // 2. Doppler beaming effect
        //  Rotate position slightly away from its actual starting position
        float3 rotatedPos = RotateAboutAxis(diskPos, diskDir, 0.01);
        float dopplerDistance = (length(rotatedPos - cameraPos) - length(diskPos - cameraPos)) / radius;
        intensity += dopplerDistance * _NoiseSpeed * _DopplerBeamingFactor;

        color = hdrIntensity(baseColor, intensity);

        //// Make color towards center hotter
        float i2 = max(0, 1 - remap(u, 0, 1, _CenterHeatMin, _CenterHeatMax));
        color =  lerp(color, baseColor * _CenterHeatIntensity, i2);

        // 3. Hue shift (distance)
        float3 hueColor = RGBToHSV(color);
        float hueShift = saturate(remap(u, _HueRadius, 1, 0, 1));
        hueColor.r += hueShift * _HueShiftFactor;
        color = HSVToRGB(hueColor);

        color = pow(color, 1.4);

        return color;
    }

    //////////////////////////// Helper functions end
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
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

            uniform sampler2D _CameraDepthTexture;

            // Vertex shader
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                // World position
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                // Object information, based upon Unity's shadergraph library functions
                // Used to mask out gravitational effect on scene texture
                o.center = UNITY_MATRIX_M._m03_m13_m23;
                o.objectScale = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                    length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                    length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)));

                // Screen position
                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            // Pixel shader
            fixed4 frag(v2f i) : SV_Target
            {
                // 1.0 Find ray information
                float3 ro = _WorldSpaceCameraPos;
                float3 rd = normalize(i.worldPos - _WorldSpaceCameraPos);

                // 1.1 Find sphere intersection for our black hole "scene" (contained in a sphere that blends into the background)
                // find the min radius for a raymarched sphere in case object isn't uniform scale
                float sphereRadius = 0.5 * min(min(i.objectScale.x, i.objectScale.y), i.objectScale.z);
                float2 outerSphereIntersection = intersectSphere(ro, rd, i.center, sphereRadius);

                // 2.0 Disk information
                // disk's direction is object's rotation, based on the local y-axis, a.k.a yaw
                float3 diskDir = normalize(mul(unity_ObjectToWorld, float4(0, 1, 0, 0)).xyz);
                // bottom and top cap positions of cylindrical disk
                //      DiskWidth determines how tall the disk is 
                float3 p1 = i.center - 0.5 * _DiskWidth * diskDir;
                float3 p2 = i.center + 0.5 * _DiskWidth * diskDir;
                // Outer radius to show the disk
                float diskRadius = sphereRadius * _DiskOuterRadius;
                // Inner radius to cut out the disk for the singularity sphere
                float innerRadius = sphereRadius * _DiskInnerRadius;

                // Raymarching info
                // Interpolator for whether or not our ray hit something
                float transmittance = 0;
                float3 position = float3(MAX_DIST, 0, 0);

                // 3.0 Raymarch
                float3 currentRayPos = ro + rd * outerSphereIntersection.x;
                float3 currentRayDir = rd;

                // 3.1 Black Hole
                //  If raymarch intersects the black hole, set mask to 1 and break out of loop, and mask out light in final colors
                float blackHoleMask = 0;
                float centerFalloff = 0;

                // Depth check
                float2 duv = i.screenPos.xy / i.screenPos.w;
                #if UNITY_UV_STARTS_AT_TOP
                    duv.y = 1 - duv.y;
                #endif

                // Convert from depth buffer (eye space) to true distance from camera
                // This is done by multiplying the eyespace depth by the length of the "z-normalized"
                // ray (see vert()).  Think of similar triangles: the view-space z-distance between a point
                // and the camera is proportional to the absolute distance.
           /*     float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, duv).r);
                depth *= length(i.worldPos - _WorldSpaceCameraPos);*/

                float d = 0; // current distance travelled along ray

                // Ray intersects with outer sphere (scene sphere)
                if (outerSphereIntersection.x < MAX_DIST)
                {
                    // Raymarching Start
                    int maxSteps = _Steps;
                    for (int j = 0; j < maxSteps; j++) 
                    {
                        // 3.3 Gravitational influence
                        //   We need to know direction and distance towards the gravitational center (singularity) with regards
                        //   to the current ray position.
                        float3 dirToCenter = i.center - currentRayPos;
                        float distToCenter = length(dirToCenter);
                        dirToCenter /= distToCenter; // normalize

                        // If ray is slightly outside radius
                        if (distToCenter > sphereRadius + _StepSize) 
                        {
                            break;
                        }

                        // Gravitational lensing
                        float force = _Gravity / (distToCenter * distToCenter);
                        force = pow(force, _GravityAdjust.x) + _GravityAdjust.y;
                        currentRayDir = normalize(currentRayDir + dirToCenter * force * _StepSize);

                        // March forward
                        currentRayPos += currentRayDir * _StepSize;

                        // 3.1 Black hole
                        // Check for collision with singularity
                        float distanceToSingularity = intersectSphere(currentRayPos, currentRayDir, i.center, _SchwarzschildRadius * sphereRadius).x;
                        if (distanceToSingularity <= _StepSize) 
                        {
                            blackHoleMask = 1;
                            break;
                        }

                        // Accretion disk
                        float diskDistance = intersectDisk(currentRayPos, currentRayDir, p1, p2, diskDir, diskRadius, innerRadius);
                        if (transmittance < 1 && diskDistance < _StepSize)
                        {
                            transmittance = 1;
                            centerFalloff = saturate((distToCenter - innerRadius) / (diskRadius - innerRadius));
                            // 2.1.1 March forward
                            position = currentRayPos + currentRayDir * diskDistance;
                        }
                    }
                }

                // 2.1 UV mapping
                // UV the accretion disk via polar coordinates
                float2 uv = float2(0, 0);
                float3 diskPos = float3(0, 0, 0);
                if (position.x < MAX_DIST) 
                {
                    diskPos = position - dot(position - i.center, diskDir) * diskDir - i.center;
                    uv = diskUV(diskPos, diskDir, i.center, diskRadius);
                    // 2.2 Animate noise
                    uv.y += _Time.x * _NoiseSpeed;
                }
                // Sample noise for accretion disk
                float noise = tex2D(_NoiseTex, uv * _NoiseTex_ST.xy).r;

                float2 uv2 = 0;
                if (position.x < MAX_DIST)
                {
                    diskPos = position - dot(position - i.center, diskDir) * diskDir - i.center;
                    uv2 = diskUV(diskPos, diskDir, i.center, diskRadius);
                    // 2.2 Animate noise
                    uv2.y += _Time.x * _SecondaryNoiseSpeed;
                }
                float secondaryNoise = tex2D(_SecondaryNoiseTex, uv2 * _SecondaryNoiseTex_ST.xy).r;
                secondaryNoise = smoothstep(_SecondaryNoiseCutoff + _SecondaryNoiseSmoothness, _SecondaryNoiseCutoff, secondaryNoise);

                noise = (pow(noise, 1.7) + secondaryNoise * 0.8);

                // Calculate screen uv and sample scene color for transparency
                float2 screenUV = i.screenPos.xy / i.screenPos.w;

                // 3.3 Space warping
                // Scene color distortion
                float3 distortedRayDir = normalize(currentRayPos - ro);
                float4 rayCameraSpace = mul(unity_WorldToCamera, float4(distortedRayDir, 0));
                float4 rayUVProj = mul(unity_CameraProjection, float4(rayCameraSpace));
                float2 distortedScreenUV = rayUVProj.xy + 1 * 0.5;

                // Screen and object edge transitions
                float edgeFadex = smoothstep(0, 0.25, 1 - abs(remap(screenUV.x, 0, 1, -1, 1)));
                float edgeFadey = smoothstep(0, 0.25, 1 - abs(remap(screenUV.y, 0, 1, -1, 1)));
                float t = saturate(remap(outerSphereIntersection.y, sphereRadius, 2 * sphereRadius, 0, 1)) * edgeFadex * edgeFadey;
                t = lerp(t, t * 0.25, sin(_Time.x * 5) * 0.5 + 0.5);
                distortedScreenUV = lerp(screenUV, distortedScreenUV, t);

                float3 backgroundColor = tex2D(_BackgroundTex, distortedScreenUV) * (1 - blackHoleMask);

                float falloff = pow(1 - centerFalloff, 1.5) * 4.5;
                // 2.3 Accretion Disk color
                float3 diskCol = diskColor(_DiskColor.rgb, diskPos, diskDir, _WorldSpaceCameraPos, uv.x, diskRadius, falloff);

                transmittance *= noise * _DiskColor.a * falloff;

                // Final output
                float3 finalColor = lerp(backgroundColor, diskCol, transmittance);

                return float4(finalColor, 1);
            }
            ENDCG
        }
    }
}
