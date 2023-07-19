Shader "Custom/AlienCrystalPyramid"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Specular ("Specular", Color) = (0.5, 0.5, 0.5, 0.5)
        _SpecularPower("Specular Power", Float) = 1
        _SpecularFalloff("Specular Fall Off", Range(0, 0.5)) = 0.2
        _SunIntensity("Sun Intensity", Float) = 1

        [Header(CubeReflection)]
        _Cube("Reflection cube map", Cube) = "" {}
        _ReflAmount("Reflection Amount", Float) = 0.5

        [Header(Rim)]
        _FresnelColor("Rim Color", Color) = (1,1,1,1)
        _FresnelPower("Rim Power", Range(0,10)) = 1
        _FresnelStrength("Rim Strength", Float) = 1
        _FresnelOpacity ("Fresnel Opacity", Range(0, 1)) = 1

        _CrystalTex ("Crystal Texture", 2D) = "black" {}
        _CrystalColor ("Crystal Color", Color) = (0, 0, 0, 0)
        _CrystalPower ("Crystal Exp", Float)= 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardSpecular fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.5

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
            INTERNAL_DATA
            float3 worldPos;
            float3 viewDir;
            float4 screenPos;
        };

        half _Glossiness;
        half _Specular;
        fixed4 _Color;
        samplerCUBE _Cube;
        float _ReflAmount;

        float _SunIntensity;
        float _SpecularPower;
        float _SpecularFalloff;

        float4 _FresnelColor;
        float _FresnelPower, _FresnelStrength, _FresnelOpacity;

        float3 Fresnel(float3 N, float3 V)
        {
            float rim = 1.0 - saturate(dot(N, V));
            rim = saturate(pow(rim, _FresnelPower)) * _FresnelStrength;
            rim = max(rim, 0); // No negatives
            return rim * _FresnelColor;
        }

        sampler2D _CrystalTex;
        float4 _CrystalTex_ST;
        float4 _CrystalColor;
        float _CrystalPower;

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            half3 worldViewDir = normalize(UnityWorldSpaceViewDir(IN.worldPos));
            float3 viewRefl = reflect(-worldViewDir, IN.worldNormal);
            float4 col = texCUBE(_Cube, viewRefl);

            o.Albedo = col.rgb;
            o.Specular = _Specular;
            o.Smoothness = _Glossiness;

            // Lighting
            float3 L = _WorldSpaceLightPos0.xyz;
            float3 V = worldViewDir;
            float3 N = IN.worldNormal;

            // Specular
            float3 R = reflect(normalize(L), N);
            float3 VdotR = dot(normalize(V), R);
            float3 specular =
                smoothstep(1 - o.Smoothness - _SpecularFalloff * 0.5, 1 - o.Smoothness + _SpecularFalloff * 0.5, VdotR);
            specular = pow(specular, _SpecularPower);
            specular *= _LightColor0;

            // Fresnel
            float3 fresnel = Fresnel(N, V);
            fresnel = 1 - fresnel;

            float2 crystalUV = IN.screenPos.xy / IN.screenPos.w * _CrystalTex_ST.xy + _CrystalTex_ST.zw;
            float4 crystalColor = tex2D(_CrystalTex, crystalUV) * _CrystalColor;
            crystalColor = pow(crystalColor, _CrystalPower);

            o.Emission = col.rgb * _ReflAmount * _Color.rgb + specular * _SunIntensity;
            float3 reflColor = o.Emission;
            o.Emission = lerp(o.Emission, crystalColor.rgb * _FresnelOpacity, fresnel);
            o.Emission = lerp(o.Emission, reflColor, 0.1);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
