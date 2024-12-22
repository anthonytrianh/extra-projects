Shader "Anthony/Anthony PBR Rain Drops Mask"
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
        [Header(Grunge)][Space]
        _GrungeTex ("Grunge Map", 2D) = "black" {}
        _GrungeOpacity ("Grunge Opacity", Range(0, 1)) = 0.4
        _GrungeCutoff ("Grunge Cutoff", Range(0, 1)) = 0.5
        _GrungeSmoothness ("Grunge Smoothness", Range(0, 0.5)) = 0.15
        _GrungeContrast ("Grunge Contrast", Float) = 1.2
        [Toggle(INVERT_GRUNGE)] _InvertGrunge ("Invert Grunge", Float) = 0
        
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
        _RainDropsMeshMask ("Rain Drops Mesh Mask", 2D) = "white" {}
        
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
            o.Albedo = color.rgb;
            o.Specular = _Specular;
            o.Smoothness = CalculateSmoothness(uv);
            o.Normal = CalculateNormals(uv);
            o.Emission = CalculateEmissiveColor(uv);
            o.Alpha = color.a;
        
            // Grunge
            o.Albedo = CalculateGrungeColor(i.worldPos.xz, o.Albedo);

            //------------------------------------
            // Rain
            //------------------------------------
            rainDropsMeshUVs = uv;
            float3 worldPos     = i.worldPos;
            float3 worldNormal  = WorldNormalVector(i, o.Normal);

            float3 outColor;
            float3 outNormal;
            float outSmoothness;
            float outSpecular;
            WeatherRain(worldPos, worldNormal, o.Albedo, o.Normal, o.Specular, o.Smoothness,
                            outColor, outNormal, outSpecular, outSmoothness);

            o.Albedo = outColor;
            o.Normal = outNormal;
            o.Smoothness = outSmoothness;
            o.Specular = outSpecular;
        }
        
        ENDCG
    }
    FallBack "Diffuse"
}