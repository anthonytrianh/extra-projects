Shader "Hidden/Custom/RainOnLens"
{
    HLSLINCLUDE

        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Colors.hlsl"
    
        #define PI 3.1415926

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
        // Scene Texture
        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);

        // Rain drops
        TEXTURE2D_SAMPLER2D(_RainDropsTex, sampler_RainDrops);
    
        // float4 _WetTileOffset;
        // float _WetStrength;
        //
        // // Blood
        // float4 _BloodColor;
        // float _BloodOpacity;
        // float _BloodStrength;
        
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

       
        ///////////////// Shader
        float4 Frag(VaryingsDefault i) : SV_Target
        {
            float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

            //// ---------------------------------------
            //// Rain Drops
            /// ----------------------------------------
            const float2 uv_centered = i.texcoord * 2 - 1; //change UV range from (0,1) to (-1,1)

            // float2 screenUV = Compute(i.vertex);
            float3 finalColor = float3(uv_centered, 0);
            
            
            // //-- Water Drops
            // float2 wetUV = uvDistorted * _WetTileOffset.xy + _WetTileOffset.zw;
            // float3 wetDistort = ComputeNormals(SAMPLE_TEXTURE2D(_WetBump, sampler_WetBump, wetUV));
            // float2 wetUVDistort = wetDistort * _WetStrength;
            // float3 distortedCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + wetUVDistort.xy).rgb;
            //
            // // Bloodiness
            // float3 bloody = dot(distortedCol, float3(0.3, 0.59, 0.11)) * _BloodColor;
            // float bloodiness = length(wetDistort.xy * _BloodStrength);
            // float3 finalColor;
            // finalColor = lerp(distortedCol, _BloodColor, saturate(bloodiness * _BloodOpacity));
            // //finalColor = lerp(distortedCol, bloody, bloodiness + _BloodIntensityAdd);

            /////////////////////////////////////////////////////////////
            ////    Colors

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