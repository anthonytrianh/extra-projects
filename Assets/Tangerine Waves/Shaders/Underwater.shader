// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Underwater"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _MaskTex("Mask Texture", 2D) = "black" {}

        [Header(Underwater)]
        _DeepColor ("Underwater Deep", Color) = (0, 1, 0)
        _ShallowColor ("Underwater Shallow", Color) = (0, 0, 1)

        _WaterlineThickness ("Water line Thickness", Range(0, 0.1)) = 0.01

        [Header(Fog)]
        _FogDensity ("Fog Density", Float) = 0.1
        _FogScale ("Fog Scale", Float) = 0
        _SSSOpacity ("SSS Opacity", Range(0, 2)) = 1

        [NoScaleOffset] _WaterOnlyTex("Water Render Texture", 2D) = "black" {}

        [Header(Snorkel)]
        _WetBump ("Wet Texture", 2D) = "bump" {}
        _WetTileOffset ("Wet Tile Offset", Vector) = (1, 1, 0, 0)
        _WetStrength ("Wet Strength", Float) = 1

        _LensDistortionTightness ("Lens Tightness", Float) = 1
        _LensDistortionStrength ("Lens Strength", Float) = 1

        [Header(Caustics)]
        [NoScaleOffset] _CausticsTex("Caustic Texture", 2D) = "black" {}
        _CausticsSpeed ("Caustic Speed", Float) = 0.15
        _CausticsTiling ("Caustic Tiling", Float) = 0.2
        _CausticsBrightness ("Caustics Brightness", Float) = 2
        _UnderwaterCausticsStrength ("Underwater Caustics Strength", Float) = 1

    }

    CGINCLUDE
    #include "UnityCG.cginc"
    #include "Lighting.cginc"

    //Current camera
    #define NEAR_PLANE _ProjectionParams.y
    #define ASPECT _ScreenParams.x / _ScreenParams.y
    #define CAM_FOV unity_CameraInvProjection._m11
    #define CAM_POS _WorldSpaceCameraPos
    #define CAM_RIGHT unity_WorldToCamera[0].xyz //Possibly flipped as well, but doesn't matter
    #define CAM_UP unity_WorldToCamera[1].xyz
    //The array variant is flipped when stereo rendering is in use. Using the camera center forward vector also works for VR
    #define CAM_FWD -UNITY_MATRIX_V[2].xyz

    float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
    {
        float steepness = wave.z;
        float wavelength = wave.w;
        float k = 2 * UNITY_PI / wavelength;
        float c = sqrt(9.8 / k);
        float s = max(abs(wave.x), abs(wave.y));
        float2 d = normalize(wave.xy);
        float f = k * (dot(d, p.xz) - c * _Time.y * s);
        float a = steepness / k;

        tangent += float3(
            -d.x * d.x * (steepness * sin(f)),
            d.x * (steepness * cos(f)),
            -d.x * d.y * (steepness * sin(f))
            );
        binormal += float3(
            -d.x * d.y * (steepness * sin(f)),
            d.y * (steepness * cos(f)),
            -d.y * d.y * (steepness * sin(f))
            );
        return float3(
            d.x * (a * cos(f)),
            a * sin(f),
            d.y * (a * cos(f))
            );
    }

    // Waves
    float4 _WaveA;
    float4 _WaveB;

    // camera
    float4x4 Ocean_InverseViewMatrix;
    float4x4 Ocean_InverseProjectionMatrix;

    uniform sampler2D _CameraDepthTexture;
    float4 _CameraDepthTexture_TexelSize;

    uniform float WaterLevel;

    float3 SampleDisplacement(float2 worldXZ)
    {
        float3 gridPoint = float3(worldXZ.x, 0, worldXZ.y);
        float3 tangent = float3(1, 0, 0);
        float3 binormal = float3(0, 0, 1);
        float3 p = gridPoint;
        p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
        p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);

        return p;
    }

    float SampleHeight(float2 worldPos)
    {
        float3 displacement = SampleDisplacement(worldPos);
        displacement = SampleDisplacement(worldPos - displacement.xz);
        displacement = SampleDisplacement(worldPos - displacement.xz);
        displacement = SampleDisplacement(worldPos - displacement.xz);

        return displacement.y + WaterLevel;
    }

    ENDCG

    SubShader
    {
        //GrabPass
        //{
        //    "_UnderwaterTex"
        //}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Shadows.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _MaskTex;

            float3 _DeepColor, _ShallowColor;
            float _WaterlineThickness;

            sampler2D _WetBump;
            float4 _WetTileOffset;
            float _WetStrength;

            float _LensDistortionTightness;
            float _LensDistortionStrength;

            float _FogDensity;
            float _FogScale;

            float4x4 unity_WorldToLight;

            struct v2f 
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.screenPos = ComputeScreenPos(o.pos);
                return o;
            }

            float _SSSOpacity;
            float3 UnderwaterFogColor(float3 bgColor, float3 viewDir, float3 lightDir, float depth) 
            {
                float depthScale = _FogScale;
                // subsurface scattering
                float bias = min(0, depth * 0.02);
                float sssFactor = 0.1 * pow(max(0, 1 - viewDir.y + bias), 3);
                sssFactor *= 1 + pow(saturate(dot(lightDir, -viewDir)), 4);
                sssFactor *= saturate(1 - depthScale);
                float3 color = _DeepColor * max(0.5, saturate(2 - viewDir.y + bias));
                float3 sssColor = _ShallowColor;
                half3 overlay = (sssColor.rgb < 0.5) ? 2 * sssColor.rgb * bgColor : 1 - 2 * (1 - sssColor.rgb) * (1 - bgColor);
                color = color + sssColor * sssFactor * _SSSOpacity;
                
                return color;
            }

            float3 ColorThroughWater(float3 color, float3 volumeColor, float distThroughWater, float depth)
            {
                distThroughWater = max(0, distThroughWater);
                depth = max(0, depth);
                //color *= AbsorptionTint(exp(-(distThroughWater + depth) / Ocean_AbsorptionDepthScale));
                return lerp(color, volumeColor, 1 - saturate(exp(-_FogDensity * distThroughWater)));
            }

            sampler2D _WaterOnlyTex;

            float4 alphaBlend(float4 top, float4 bottom)
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
                float alpha = top.a + bottom.a * (1 - top.a);

                return float4(color, alpha);
            }

            float4x4 _ShadowMatrix;

            sampler2D _CausticsTex;
            float _CausticsBrightness;
            float _CausticsSpeed;
            float _CausticsTiling;
            float _UnderwaterCausticsStrength;

            float3 SampleCaustics(float2 uv, float2 time, float tiling)
            {
                float3 caustics1 = tex2D(_CausticsTex, uv * tiling + (time.xy)).rgb;
                float3 caustics2 = tex2D(_CausticsTex, (uv * tiling * 0.8) - (time.xy)).rgb;

                float3 caustics = min(caustics1, caustics2);

                return caustics;
            }

            float3 ViewSpacePosition(float2 uv, v2f input)
            {
                float rawDepth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(input.screenPos)).r;

#if UNITY_REVERSED_Z //Anything other than OpenGL + Vulkan
                rawDepth = (1.0 - rawDepth) * 2.0 - 1.0;
#else
                rawDepth = lerp(UNITY_NEAR_CLIP_VALUE, 1, rawDepth);
#endif
                float4 positionCS = float4(uv * 2 - 1, rawDepth, 1);
                float4 positionVS = mul(Ocean_InverseProjectionMatrix, positionCS);
                positionVS /= positionVS.w;

                float4 positionWS = mul(Ocean_InverseViewMatrix, positionVS);

                return positionWS;
            }

            float3 GetWorldNormal(v2f input)
            {
                half3 viewNormal = 0;

                //https://wickedengine.net/2019/09/22/improved-normal-reconstruction-from-depth/

                // get current pixel's view space position
                const half3 center = ViewSpacePosition(input.uv, input);

                return center;

                // get view space position at 1 pixel offsets in each major direction
                const half3 left = ViewSpacePosition(input.uv - float2(1 / _ScreenParams.x, 0.0), input);
                const half3 up = ViewSpacePosition(input.uv + float2(0.0, 1 / _ScreenParams.y), input);
                const half3 right = ViewSpacePosition(input.uv + float2(1 /_ScreenParams.x, 0.0), input);
                const half3 down = ViewSpacePosition(input.uv - float2(0.0,1 / _ScreenParams.y), input);

                // get the difference between the current and each offset position
                half3 l = center - left;
                half3 r = right - center;
                half3 d = center - down;
                half3 u = up - center;

                // pick horizontal and vertical diff with the smallest z difference
                const half3 H = abs(l.z) < abs(r.z) ? l : r;
                const half3 V = abs(d.z) < abs(u.z) ? d : u;

                // get view space normal from the cross product of the diffs
                viewNormal = normalize(cross(H, V));

                float3 worldNormal = mul((float3x3)unity_CameraToWorld, viewNormal);

                return worldNormal;
            }

            float4 frag(v2f input) : SV_Target
            {
                //return float4(input.uv, 0, 1);

                float submergence = //GaussianBlur(_MaskTex, input.uv).r;
                    tex2D(_MaskTex, input.uv).r;

                float safetyMargin = 0.045;
                float waterlineThickness = _WaterlineThickness;
                float cutoff = smoothstep(safetyMargin - waterlineThickness, safetyMargin, -(submergence - 0.55));
                    //step(safetyMargin, -(submergence - 0.55));
                //return submergence;

                // Wet 
                const float2 uv_centered = input.uv * 2 - 1; //change UV range from (0,1) to (-1,1)
                const float distortionMagnitude = abs(uv_centered[0] * uv_centered[1]);
                //const float smoothDistortionMagnitude = pow(distortionMagnitude, _LensDistortionTightness);//use exponential function
                  // const float smoothDistortionMagnitude=1-sqrt(1-pow(distortionMagnitude,_LensDistortionTightness));//use circular function
                const float smoothDistortionMagnitude=pow(sin(UNITY_HALF_PI*distortionMagnitude),_LensDistortionTightness);// use sinusoidal function
                float2 uvDistorted = input.uv + uv_centered * smoothDistortionMagnitude * _LensDistortionStrength; //vector of distortion and add it to original uv

                //Handle out of bound uv
                if (uvDistorted[0] < 0 || uvDistorted[0] > 1 || uvDistorted[1] < 0 || uvDistorted[1] > 1) {
                    uvDistorted = saturate(uvDistorted); //uv out of bound so display out of bound color
                }

                float2 wetUV = uvDistorted * _WetTileOffset.xy + _WetTileOffset.zw;
                wetUV = lerp(wetUV, input.uv, cutoff);
                fixed3 wetDistort = UnpackNormal(tex2D(_WetBump, wetUV));
                wetDistort = wetDistort * _WetStrength;
                wetDistort = lerp(wetDistort, 0, submergence);


                // float3 underwater = lerp(_DeepColor, _ShallowColor, submergence);
           
                // Underwater
                float rawDepth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(input.screenPos)).r;
                float4 positionCS = float4(input.uv * 2 - 1, rawDepth, 1);
                float4 positionVS = mul(Ocean_InverseProjectionMatrix, positionCS);
                positionVS /= positionVS.w;
                float3 viewDir = -mul(Ocean_InverseViewMatrix, float4(positionVS.xyz, 0)).xyz;
                float viewDist = length(positionVS);
                viewDir /= viewDist;
                float4 positionWS = mul(Ocean_InverseViewMatrix, positionVS);

                float3 lightDir = _WorldSpaceLightPos0.rgb;

                float2 underwaterUV = input.screenPos.xy / input.screenPos.w;
                #if UNITY_UV_STARTS_AT_TOP
                    if (_CameraDepthTexture_TexelSize.y < 0) {
                        underwaterUV.y = 1 - underwaterUV.y;
                    }
                #endif

                float4 waterMask = tex2D(_WaterOnlyTex, input.uv);
                float mask = saturate(dot(float3(0.26, 0.67, 0.13), waterMask.rgb));

                // Colors
                float3 col = tex2D(_MainTex, input.uv).rgb;

                float3 underwaterBackground = tex2D(_MainTex, input.uv);
                float3 volume = UnderwaterFogColor(col, viewDir, lightDir, _WorldSpaceCameraPos.y);
                float3 underwaterColor = //positionVS;
                    ColorThroughWater(col, volume,
                    viewDist - _ProjectionParams.y, -positionWS.y);

                // Final Color
                float3 finalColor = lerp(col, underwaterColor, cutoff * pow((1 - mask), 1.2));

                float3 disortedCol = tex2D(_MainTex, input.uv + wetDistort).rgb;
                finalColor = lerp(disortedCol, finalColor, cutoff);

                // Shadows
                float shadowAtten = GetSunShadowsAttenuation(positionWS, 0);
                float shadowMask = 1 - shadowAtten;

                // CAUSTICSSSS BOIIII!!!
                float3 worldPos = positionWS.xyz;
                float2 projection = worldPos.xz;
                // Light projection
                float3 lightProj = mul((float4x4)unity_WorldToLight, float4(worldPos, 1.0)).xyz;
                projection = lightProj.xy;

                // Masks
                float skyboxMask = Linear01Depth(rawDepth) > 0.99 ? 1 : 0;
                float underwaterMask = cutoff * (1 - skyboxMask);

                float bias = min(WaterLevel, _WorldSpaceCameraPos.y * 0.02);
                float waterDensity = 0.2 * pow(max(0, 1 - viewDir.y + bias), 3);
                waterDensity *= 1.5 + pow(saturate(dot(lightDir, -viewDir)), 4);
                waterDensity *= saturate(1 - _FogScale);
                ///// Caustics
                // Sample caustics
                float3 caustics = SampleCaustics(projection, _Time.y * _CausticsSpeed, _CausticsTiling) * _CausticsBrightness;
                caustics *= underwaterMask * (waterDensity);
                caustics *= _UnderwaterCausticsStrength;

                float3 worldNormal = GetWorldNormal(input);
                float NdotL = saturate(dot(worldNormal, _WorldSpaceLightPos0.xyz));
                //caustics *= NdotL;

                //return float4(worldNormal, 1);

                finalColor += caustics;

                return float4(finalColor, 1);
            }
            ENDCG
        }
    }
}
