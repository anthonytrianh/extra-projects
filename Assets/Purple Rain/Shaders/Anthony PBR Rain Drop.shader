Shader "Anthony/Anthony PBR Rain Drop"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        [Header(Roughness)][Space]
        _RoughnessTex("Roughness Map", 2D) = "black" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        
        [Header(Specular)][Space]
        _Specular ("Specular", Range(0, 1)) = 0.5

        [Header(Normals)][Space]
        _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpStrength("Bump Strength", Float) = 1

        [Header(Emission)][Space]
        [Toggle(EMISSIVE)] _Emission ("Emission?", Float) = 0
        _EmissiveTex("Emission Texture", 2D) = "black" {}
        [HDR] _EmissiveColor("Emissive Color", Color) = (0, 0, 0, 0)

        [Header(HeightParallax)][Space]
        [Toggle(PARALLAX)] _UseParallax("Height?", Int) = 0
        [NoScaleOffset] _ParallaxTex("Height Tex", 2D) = "white" {}
        _Height("Height", Float) = 0

        [Toggle(FLIP_V)] _FlipY("Flip Y?", Float) = 0

        [Toggle(VERT_GRADIENT)] _VerticalGradient ("Veritcal Gradient Color?", Float) = 0
        _VerticalColorTop ("Color Top", Color) = (1,1,1,1)
        _VerticalColorBot ("Color Bottom", Color) = (0.5, 0.5, 0.5, 1)
        
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
    
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert_pbr
        #pragma target 4.0

        void surf(Input i, inout SurfaceOutputStandard o)
        {
            float2 uv = CalculateUv(i);
            float parallax = GetParallaxOffset(uv, _Height, i.viewDir);
            #ifdef PARALLAX
            uv += parallax;
            #endif

            float4 color = CalculateAlbedo(uv);
            o.Albedo = color;
            o.Metallic = CalculateMetallic(uv);
            o.Emission = CalculateEmissiveColor(uv);
            o.Alpha = color.a;

            
            // Get world normal up to mask rain drops
            float3 worldNormal = WorldNormalVector(i, o.Normal);
            float3 dropsNormal;
            float roughness;
            RainDrops(uv, worldNormal, dropsNormal, roughness);

            o.Smoothness = 1 - roughness;
            o.Normal = dropsNormal;
        }
        
        ENDCG
    }
    FallBack "Diffuse"
}