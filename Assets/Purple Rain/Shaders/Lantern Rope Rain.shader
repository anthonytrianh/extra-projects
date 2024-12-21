Shader "Anthony/Lantern Rope Rain"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        
         [Header(Metallic)][Space]
        _MetallicTex("Metallic Map", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0

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
        
        [Header(Raindrops)][Space]
        _RainDropsTex ("Rain Drops Texture", 2D) = "bump" {}
        _RainDropsNormalStrength ("Rain Normal Strength", Float) = 2
        _RainDropsAnimSpeed ("Rain Drops Animation Speed", Float) = 0.7
        _RainDropsAmount ("Rain Drops Amount", Range(0, 1)) = 1
        _RainDropsRoughnessPower ("Rain Drops Roughness Power", Float) = 0.1
    }
    
    CGINCLUDE
    #include "AnthonyPBR.cginc"
    #include "RainDrops.cginc"

    sampler2D _EmissiveMask;
    float4 _EmissiveMask_ST;
    float4 _EmissionMovement;
    float _Amplitude;
    float4 _EmissiveColorA;
    float4 _EmissiveColorB;
    
    void surf(Input i, inout SurfaceOutputStandard o)
    {
        APBR_uv(i);
        APBR_Albedo(o, uv);
        APBR_Metal(o, uv);
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

        // Rain drops
        float3 worldNormal = WorldNormalVector(i, o.Normal);
        float3 dropsNormal;
        float roughness;
        RainDrops(uv, worldNormal, dropsNormal, roughness);
        float3 baseNormal = o.Normal;
        o.Normal =
            normalize(float3(baseNormal.xy + dropsNormal.xy, baseNormal.z * dropsNormal.z));
        o.Smoothness += (1 - roughness);
        
    }
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert_pbr
        #pragma target 4.0

        ENDCG
    }
    FallBack "Diffuse"
}