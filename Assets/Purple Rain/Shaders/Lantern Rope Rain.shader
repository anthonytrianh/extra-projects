Shader "Anthony/Lantern Rope Rain"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        
        [Header(Specular)][Space]
        _Specular ("Specular", Range(0, 1)) = 0.5

        [Header(Roughness)][Space]
        _RoughnessTex("Roughness Map", 2D) = "black" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5

        [Header(Normals)][Space]
        _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpStrength("Bump Strength", Float) = 1

        [Header(Emission)][Space]
        _EmissiveMask ("Emissive Mask", 2D) = "white" {}
        _EmissiveTex("Emission Texture", 2D) = "black" {}
        _EmissionMovement ("Emissive Movement", Vector) = (0, 1, 0, 0)
        [HDR] _EmissiveColorA("Emissive Color A", Color) = (0, 0, 0, 0)
        [HDR] _EmissiveColorB("Emissive Color B", Color) = (0, 0, 0, 0)
        _Amplitude ("Amplitude", Float) = 1
        
        [Header(Rain)] [Space]
        _Rain ("Rain", Range(0, 1)) = 1
        _RainSmoothnessPower ("Rain Smoothness Power", Float) = 0.1
        
        [Header(Wetness)][Space]
        _WetnessSaturation ("Wet Saturation", Float) = 1
        _WetnessColorDarken ("Wet Color Darken", Float) = 0.5
        _Wetness ("Wetness", Range(0, 1)) = 0.5
        // How water absorbent is the surface?
        _Porousness ("Porousness", Range(0, 1)) = 0.2
        
         [Header(Raindrops)][Space]
         _RainDropsTex ("Rain Drops Texture", 2D) = "bump" {}
         _RainDropsScale ("Rain Drops Scale", Float) = 1
         _RainDropsNormalStrength ("Rain Normal Strength", Float) = 2
         _RainDropsAnimSpeed ("Rain Drops Animation Speed", Float) = 0.7
         _RainDropsAmount ("Rain Drops Amount", Float) = 10
         _RainDropsSmoothnessPower ("Rain Drops Smoothness Power", Float) = 0.1
        
        [Header(Raindrips)][Space]
        _RainDripsTex ("Rain Drips Texture", 2D) = "bump" {}
        _RainDripsWorldScale ("Rain Drips World Scale", Float) = 1
        _RainDripMask ("Rain Drip Mask", 2D) = "black" {}
        _RainDripMaskScale ("Rain Drip Mask Scale", Vector) = (1, 1.05, 1, 0)
        _RainDripsSpeedFast ("Rain Drip Speed Min Max", Vector) = (0.25, 0.7, 0, 0)
        _RainDripsSpeedSlow ("Rain Drip Speed Min Max", Vector) = (0.03, 0.125, 0, 0)
        _RainDripsStrength ("Rain Drips Strength", Float) = 1
        _RainDripsSmoothnessContrast ("Rain Drips Smoothness Contrast", Float) = 1.2
    }
    
    CGINCLUDE
    #include "AnthonyPBR.cginc"
    #include "Rain.cginc"

    sampler2D _EmissiveMask;
    float4 _EmissiveMask_ST;
    float4 _EmissionMovement;
    float _Amplitude;
    float4 _EmissiveColorA;
    float4 _EmissiveColorB;
    
    void surf(Input i, inout SurfaceOutputStandardSpecular o)
    {
        APBR_uv(i);
        APBR_Albedo(o, uv);
        APBR_Smoothness(o, uv);
        APBR_Normal(o, uv);
        o.Alpha = 1;

        // Emission
        float emissiveMask = tex2D(_EmissiveMask, uv * _EmissiveMask_ST.xy + _EmissiveMask_ST.zw);
        float2 emissionUV = uv * _EmissiveTex_ST.xy + _EmissiveTex_ST.zw + _Time.y * _EmissionMovement.xy;

        float wave = cos(_Amplitude * (uv.y + _Time.y * _EmissionMovement.x) * UNITY_TWO_PI);
        wave = wave * 0.5 + 0.5;
        float3 emissiveColor = lerp(_EmissiveColorA, _EmissiveColorB, wave);
        o.Emission = emissiveColor * emissiveMask;

        // Rain 
        float3 worldPos = i.worldPos;
        float3 worldNormal  = WorldNormalVector(i, o.Normal);
        float3 outColor;
        float3 outNormal;
        float outSmoothness;
        float outSpecular;
        WeatherRain(worldPos, worldNormal, o.Albedo, o.Normal, o.Specular, o.Smoothness, outColor, outNormal, outSpecular, outSmoothness);
        o.Albedo = outColor;
        o.Normal = outNormal;
        o.Smoothness = outSmoothness;
        o.Specular = outSpecular;
    }
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf StandardSpecular fullforwardshadows vertex:vert_pbr
        #pragma target 4.0

        ENDCG
    }
    FallBack "Diffuse"
}