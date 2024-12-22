Shader "Anthony/Glass Rain"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        [Header(Glass)][Space]
        _IOR ("Index of Reflection", Float) = 1.35
        _Opacity ("Opacity", Range(0, 1)) = 1
        _Reflectivity ("Reflectivity", Range(0, 1)) = 1
        
        [Header(Fresnel)][Space]
        _Fresnel ("Fresnel", Range(0, 1)) = 1
        _FresnelPower ("Fresnel Power", Float) = 1
        [HDR] _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        
        [Header(VerticalEmission)][Space]
        _VGlow ("Vertical Glow Opacity", Range(0, 1)) = .5
        [HDR] _VGlowTop ("Vertical Glow Top", Color) = (0,0,0,0)
        [HDR] _VGlowBot ("Vertical Glow Bot", Color) = (0,0,0,0)
        _VGlowContrast ("Vertical Glow Contrast", Float) = 1
        
        [Header(Roughness)][Space]
        _Glossiness ("Smoothness", Range(0,1)) = 1
        
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
         _RainDropsNormalStrength ("Rain Normal Strength", Float) = 3
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
        _RainDripsStrength ("Rain Drips Strength", Float) = 4
        _RainDripsSmoothnessContrast ("Rain Drips Smoothness Contrast", Float) = 1.2
    }
    
    CGINCLUDE
    #include "PBRCommons.cginc"
    #include "Glass.cginc"
    #include "Rain.cginc"

    float _Fresnel, _FresnelPower;
    float4 _FresnelColor;
    float4 _VGlowTop, _VGlowBot;
    float _VGlow, _VGlowContrast;
    
    // Fresnel
    float fresnel(float3 viewDir, float3 normal, float exp)
    {
        float3 V = viewDir;
        float3 N = normal;

        return pow(1 - saturate(dot(V, N)), exp);
    }

    float3 GetFresnelColor(float3 viewDir, float3 normal)
    {
        return fresnel(viewDir, normal, _FresnelPower) * _FresnelColor * _Fresnel;
    }
        
    ENDCG
    
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent"
            "Queue"="Transparent" 
        }
        LOD 200

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite On
        
        GrabPass
        {
            "_BackgroundTex"
        }
        
        CGPROGRAM
        #pragma surface surf StandardSpecular fullforwardshadows vertex:vert_glass alpha
        #pragma target 4.0

        void surf(Input i, inout SurfaceOutputStandardSpecular o)
        {
            float2 uv = i.uv_MainTex;
            float4 color = CalculateAlbedo(uv);
            o.Albedo = color.rgb;
            o.Specular = _Specular;
            o.Smoothness = CalculateSmoothness(uv);
            o.Normal = CalculateNormals(uv);
            o.Emission = CalculateEmissiveColor(uv);

            float3 worldPos     = i.worldPos;
            float3 worldNormal  = WorldNormalVector(i, o.Normal);
        
            //------------------------------------
            // Rain
            //------------------------------------

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

            // Glass
            o.Emission += FragmentGlassColor(i, worldNormal);
            o.Emission += GetFresnelColor(i.viewDir, o.Normal);
            o.Alpha = _Opacity;

            o.Emission += lerp(_VGlowTop, _VGlowBot, pow(uv.y, _VGlowContrast)) * _VGlow;
        }
        
        ENDCG
    }
    FallBack "Diffuse"
}