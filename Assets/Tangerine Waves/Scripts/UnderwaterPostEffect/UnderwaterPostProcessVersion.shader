Shader "Hidden/Custom/UnderwaterPostProcessVersion"
{
  

    HLSLINCLUDE

        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Colors.hlsl"

        #define OCEAN_PI 3.1415926

        struct Attributes 
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings 
        {
            float4 positionCS : SV_POSITION;
            float2 texcoord : TEXCOORD0;
            float4 screenPos : TEXCOORD1;
        };


        //////////////// Variables
        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);

        TEXTURE2D_SAMPLER2D(_MaskTex, sampler_MaskTex);

        TEXTURE2D_SAMPLER2D(_WaterBackfaceTex, sampler_WaterBackfaceTex);

        TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);
        float4 _CameraDepthTexture_ST;
        float4 _CameraDepthTexture_TexelSize;

        float4x4 Ocean_InverseProjectionMatrix;
        float4x4 Ocean_InverseViewMatrix;

        float4 _WorldSpaceLightPos0;
        float4 _LightColor0;
        float4x4 unity_WorldToLight;

        // Undewater mask
        float _WaterlineThickness;

        // Underwater Color
        float4 _DeepColor;
        float4 _ShallowColor;
        float _FogDensity;
        float _FogScale;
        float _SSSOpacity;

        // Lens Distortion
        float _LensDistortionTightness;
        float _LensDistortionStrength;

        // Water drops
        TEXTURE2D_SAMPLER2D(_WetBump, sampler_WetBump);
        float4 _WetTileOffset;
        float _WetStrength;
        
        // Caustics
        TEXTURE2D_SAMPLER2D(_CausticsTex, sampler_CausticsTex);
        float _CausticsBrightness;
        float _CausticsSpeed;
        float _CausticsTiling;
        float _UnderwaterCausticsStrength;

        ////////////////// Functions
        float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
        {
            float steepness = wave.z;
            float wavelength = wave.w;
            float k = 2 * 3.1415926 / wavelength;
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

        float3 ComputeNormals(float4 packedNormal, float scale = 1.0)
        {
            #if defined(UNITY_NO_DXT5nm)
                return packedNormal.xyz * 2 - 1;
            #else
                packedNormal.x *= packedNormal.w;
                float3 normal;
                normal.xy = packedNormal.xy * 2 - 1;
                normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
                return normal;
            #endif
        }

        float3 UnderwaterFogColor(float3 bgColor, float3 viewDir, float3 lightDir, float depth, out float waterDensity)
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
            color = color + (sssColor + _LightColor0.rgb * _LightColor0.a) * sssFactor * _SSSOpacity;

            waterDensity = sssFactor;

            return color;
        }

        float3 ColorThroughWater(float3 color, float3 volumeColor, float distThroughWater, float depth)
        {
            distThroughWater = max(0, distThroughWater);
            depth = max(0, depth);
            //color *= AbsorptionTint(exp(-(distThroughWater + depth) / Ocean_AbsorptionDepthScale));
            return lerp(color, volumeColor, 1 - saturate(exp(-_FogDensity * distThroughWater)));
        }

        float3 SampleCaustics(float2 uv, float2 time, float tiling)
        {
            float3 caustics1 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, uv * tiling + (time.xy)).rgb;
            float3 caustics2 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, (uv * tiling * 0.8) - (time.xy)).rgb;
            float3 caustics = min(caustics1, caustics2);
            return caustics;
        }

        ///////////////// Shader
        float4 Frag(VaryingsDefault i) : SV_Target
        {
            float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

            //////////////////////////////////////////////////////////////
            ////    Underwater Mask
            float submergence = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.texcoord).r;
            float safetyMargin = 0.045;
            float waterlineThickness = _WaterlineThickness;
            float cutoff = smoothstep(safetyMargin - waterlineThickness, safetyMargin, -(submergence - 0.55));
                //return submergence;

            //////////////////////////////////////////////////////////////
            ////    Snorkel Effect
            //-- Lens Distortion
            const float2 uv_centered = i.texcoord * 2 - 1; //change UV range from (0,1) to (-1,1)
            const float distortionMagnitude = abs(uv_centered[0] * uv_centered[1]);
            float halfPi = OCEAN_PI * 0.5;
            const float smoothDistortionMagnitude = pow(sin(halfPi * distortionMagnitude), _LensDistortionTightness);
            float2 uvDistorted = i.texcoord + uv_centered * smoothDistortionMagnitude * _LensDistortionStrength;
            //Handle out of bound uv
            if (uvDistorted[0] < 0 || uvDistorted[0] > 1 || uvDistorted[1] < 0 || uvDistorted[1] > 1) {
                uvDistorted = saturate(uvDistorted); //uv out of bound so display out of bound color
            }
                //return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvDistorted);

            //-- Water Drops
            float2 wetUV = uvDistorted * _WetTileOffset.xy + _WetTileOffset.zw;
            wetUV = lerp(wetUV, i.texcoord, cutoff);
            float3 wetDistort = ComputeNormals(SAMPLE_TEXTURE2D(_WetBump, sampler_WetBump, wetUV));
            wetDistort = wetDistort * _WetStrength;
            float3 distortedCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + wetDistort.xy).rgb;

            /////////////////////////////////////////////////////////////
            ////    Depth
            float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoordStereo);
            float4 positionCS = float4(i.texcoord * 2 - 1, rawDepth, 1);
            float4 positionVS = mul(Ocean_InverseProjectionMatrix, positionCS);
            positionVS /= positionVS.w;
            float3 viewDir = -mul(Ocean_InverseViewMatrix, float4(positionVS.xyz, 0)).xyz;
            float viewDist = length(positionVS);
            viewDir /= viewDist;
            float4 positionWS = mul(Ocean_InverseViewMatrix, positionVS);
            float3 lightDir = _WorldSpaceLightPos0.rgb;
            float2 screenPos = i.texcoordStereo;

            float3 underwaterBackground = color;
            // Fog density color
            float waterDensity;
            float3 waterFog = UnderwaterFogColor(color, viewDir, lightDir, _WorldSpaceCameraPos.y, waterDensity);
            // Objects behind water color
            float distanceInWater = viewDist - _ProjectionParams.y;
            float3 underwaterColor = ColorThroughWater(color, waterFog, distanceInWater, -positionWS.y);

            // Masking out water backface
            float4 waterBackface = SAMPLE_TEXTURE2D(_WaterBackfaceTex, sampler_WaterBackfaceTex, i.texcoord);
            float waterBackfaceMask = saturate(dot(float3(0.2126729, 0.7151522, 0.0721750), waterBackface.rgb));

            //////////////////////////////////////////////////////////////
            ////    Caustics
            float3 worldPos = positionWS.xyz;
            float2 projection = worldPos.xz;
            // Light projection
            float3 lightProj = mul((float4x4)unity_WorldToLight, float4(worldPos, 1.0)).xyz;
            projection = lightProj.xy;
            // Masks
            float skyboxMask = Linear01Depth(rawDepth) > 0.99 ? 1 : 0;
            float underwaterMask = cutoff * (1 - skyboxMask);

            float3 caustics = SampleCaustics(projection, _Time.y * _CausticsSpeed, _CausticsTiling) * _CausticsBrightness;
            caustics *= underwaterMask * (waterDensity);
            caustics *= _UnderwaterCausticsStrength;

            /////////////////////////////////////////////////////////////
            ////    Colors
            float3 gradient = lerp(_DeepColor, _ShallowColor, i.texcoord.y);
            float3 finalColor = lerp(distortedCol, underwaterColor, cutoff * (1- waterBackfaceMask));
            finalColor += caustics;

            // this only
            finalColor = distortedCol;

            return float4(finalColor, 1);
        }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

            Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment Frag

            ENDHLSL
        }
    }
}