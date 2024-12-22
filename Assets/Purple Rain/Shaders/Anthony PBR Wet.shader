Shader "Anthony/Anthony PBR Wet"
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
        
        [Space]
        [Header(Wetness)][Space]
        _WetnessSaturation ("Wet Saturation", Float) = 1
        _WetnessColorDarken ("Wet Color Darken", Float) = 0.5
        _Wetness ("Wetness", Range(0, 1)) = 0.5
        // How water absorbent is the surface?
        _Porousness ("Porousness", Float) = 0.2
        
        [Space]
        [Header(Grunge)][Space]
        _GrungeTex ("Grunge Map", 2D) = "black" {}
        _GrungeOpacity ("Grunge Opacity", Range(0, 1)) = 0.4
        _GrungeCutoff ("Grunge Cutoff", Range(0, 1)) = 0.5
        _GrungeSmoothness ("Grunge Smoothness", Range(0, 0.5)) = 0.15
        _GrungeContrast ("Grunge Contrast", Float) = 1.2
        [Toggle(INVERT_GRUNGE)] _InvertGrunge ("Invert Grunge", Float) = 0
    }
    
    CGINCLUDE
    #include "AnthonyPBR.cginc"
    #include "Wetness.cginc"
    #pragma shader_feature INVERT_GRUNGE

    sampler2D _GrungeTex;
    float4 _GrungeTex_ST;
    float _GrungeOpacity;
    float _GrungeCutoff;
    float _GrungeSmoothness;
    float _GrungeContrast;

    float3 CalculateGrungeColor(float2 worldXZ, float3 albedo)
    {
        float2 grungeUV = worldXZ / _GrungeTex_ST.xy + _GrungeTex_ST.zw;
        float3 grungeSample = tex2D(_GrungeTex, grungeUV);
        float grunge = smoothstep(_GrungeCutoff, _GrungeCutoff + _GrungeSmoothness, grungeSample);
        grunge = saturate(pow(grunge, _GrungeContrast));
        #ifdef INVERT_GRUNGE
            grunge = 1 - grunge;
        #endif
        return lerp(albedo, albedo * grunge, _GrungeOpacity);
    }
    
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf StandardSpecular fullforwardshadows vertex:vert_pbr
        #pragma target 4.0

        void surf(Input i, inout SurfaceOutputStandardSpecular o)
        {
            float2 uv = CalculateUv(i);
            float parallax = GetParallaxOffset(uv, _Height, i.viewDir);
            #ifdef PARALLAX
            uv += parallax;
            #endif

            float4 color = CalculateAlbedo(uv);
            o.Normal = CalculateNormals(uv);
            o.Emission = CalculateEmissiveColor(uv);
            o.Alpha = color.a;
        
            o.Albedo = CalculateWetColor(color, _Wetness, _Porousness) * 1;
            o.Specular = CalculateWetSpecular(_Specular);
            o.Smoothness = CalculateWetSmoothness(CalculateSmoothness(uv));

            // Grunge
            o.Albedo = CalculateGrungeColor(i.worldPos.xz, o.Albedo);
        }
        
        ENDCG
    }
    FallBack "Diffuse"
}