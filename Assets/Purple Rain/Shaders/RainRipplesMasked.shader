// From: https://www.youtube.com/watch?v=ABWzKYc6UQ0
Shader "Custom/Rain Ripples Masked"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Cutoff ("Cutoff", Range(0, 1)) = 0.33
        
        [Header(Rain)][Space]
        [Header(RippleMain)][Space]
        _RipplesTex ("Ripples Texture", 2D) = "white" {}
        _RippleContrast ("Ripple Contrast", Float) = 20
        _RipplePeriod ("Ripple Period", Float) = 5
        _RippleStrength ("Ripple Strength", Float) = 0.35
        _RippleIntensity ("Ripple Intensity", Range(0, 1)) = 1
        
        [Header(RippleParams)][Space]
        _RipplesTimeScales ("Ripples Time Scales", Vector) = (1, 0.8, 0.92, 1.1)
        _RipplesTimeOffsets ("Ripples Time Offsets", Vector) = (0, 0.2, 0.44, 0.67)
        _RipplesWeightOffsets ("Ripples Weight Offsets", Vector) = (0, 0.25, 0.5, 0.75)
        _RipplesTilings ("Ripples Tilings", Vector) = (20, 10, 5, 2)
        
        [Header(RippleOffsets)][Space]
        _RipplesOffset1 ("Ripple Offset 1", Vector) = (0, 0, 0, 0)
        _RipplesOffset2 ("Ripple Offset 2", Vector) = (-0.5, 0.3, 0, 0)
        _RipplesOffset3 ("Ripple Offset 3", Vector) = (0.44, 0.8, 0, 0)
        _RipplesOffset4 ("Ripple Offset 4", Vector) = (0.55, -0.7, 0, 0)
        
        [Header(RippleWind)][Space]
        _WindRippleTex ("Wind Ripples Texture", 2D) = "bump" {}
        _WindRippleParams1 ("Wind Ripples 1 Tiling (XY) Speed (ZW)", Vector) = (20, 17, .4, .02)
        _WindRippleParams2 ("Wind Ripples 2 Tiling (XY) Speed (ZW)", Vector) = (5, 8, -.1, .4)
        _WindRippleStrength ("Wind Strength Min Max", Vector) = (0.1, 0.5, 0, 0)
        _WindRipple ("Wind Ripples", Range(0, 1)) = 1
        _WindRippleOpacity ("Wind Ripple Opacity", Range(0, 1)) = 1
        
        [Header(Puddles)][Space]
        _PuddlesTex ("Puddle Mask", 2D) = "white" {}
        _PuddlesCutoff ("Puddles Cutoff", Range(0, 1)) = 0.5
        _PuddlesSmoothness ("Puddles Smoothness", Range(0, 0.5)) = 0.1
        _PuddlesContrast ("Puddles Contrast", Float) = 1
        
        [Header(Reflections)][Space]
        _ReflectionTex("Reflection Texture", 2D) = "black" {}
        _Reflectivity ("Reflectivity", Range(0, 1)) = 0.9
        _ReflectDistortionStrength ("Reflection Distortion Strength", Float) = 0.2
    }
    
    CGINCLUDE

    #include "Rain.cginc"
    
     struct Input
    {
        float2 uv_MainTex;
        float3 worldPos;
        float4 screenPos;
    };

    sampler2D _MainTex;
    half _Glossiness;
    half _Metallic;
    fixed4 _Color;
    float _Cutoff;
    
    sampler2D _PuddlesTex;
    float4 _PuddlesTex_ST;
    float _PuddlesCutoff;
    float _PuddlesSmoothness;
    float _PuddlesContrast;

    sampler2D _ReflectionTex;
    float _Reflectivity;
    float _ReflectDistortionStrength;
    ENDCG
    
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
        }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alphatest:_Cutoff alpha:fade
        #pragma target 4.0
        
        void surf (Input i, inout SurfaceOutputStandard o)
        {
            float2 uv = i.uv_MainTex;
        
            fixed4 c = tex2D (_MainTex, i.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            ///////////////////////////////////
            // Ripples
            //////////////////////////////////
            float2 ripplesUV = i.worldPos.xz;

            float3 ripples1 = RainRippleLayer(ripplesUV, _RipplesTilings.x, _RipplesOffset1, _RipplesTimeScales.x, _RipplesTimeOffsets.x ,_RipplesWeightOffsets.x);
            float3 ripples2 = RainRippleLayer(ripplesUV, _RipplesTilings.y, _RipplesOffset2, _RipplesTimeScales.y, _RipplesTimeOffsets.y ,_RipplesWeightOffsets.y);
            float3 ripples3 = RainRippleLayer(ripplesUV, _RipplesTilings.z, _RipplesOffset3, _RipplesTimeScales.z, _RipplesTimeOffsets.z ,_RipplesWeightOffsets.z);
            float3 ripples4 = RainRippleLayer(ripplesUV, _RipplesTilings.w, _RipplesOffset4, _RipplesTimeScales.w, _RipplesTimeOffsets.w ,_RipplesWeightOffsets.w);

            float4 rippleWeights = saturate((_RippleIntensity - _RipplesWeightOffsets) * 4);
            float3 ringsNormal = BlendRipplesNormals4(rippleWeights, ripples1, ripples2, ripples3, ripples4);

            // Wind ripples
            float3 windRipplesNormal = WindRipple(i.worldPos.xz);
            float3 ripplesNormal = float3(ringsNormal.xy + windRipplesNormal.xy, 1);
        
            // Output
            o.Normal = ripplesNormal;

            //////////////////////////////
            // Puddles masking
            float2 puddlesUV = (i.worldPos.xz / _PuddlesTex_ST.xy) + _PuddlesTex_ST.zw;
            fixed puddleSample = tex2D(_PuddlesTex, puddlesUV);
            fixed puddleMask = smoothstep(_PuddlesCutoff, _PuddlesCutoff + _PuddlesSmoothness, puddleSample);
            puddleMask = pow(puddleMask, _PuddlesContrast);
            o.Alpha = puddleMask;
            clip(puddleMask - _Cutoff);

            ////////////////////////////////
            // Reflection
            float2 screenUV = i.screenPos.xy / i.screenPos.w;
            float2 reflectionUV = screenUV - o.Normal.xy * _ReflectDistortionStrength;
            float4 reflectionSample = tex2D(_ReflectionTex, reflectionUV);
            o.Emission = lerp(0, reflectionSample.rgb, _Reflectivity) * puddleMask;

            o.Alpha *= _Color.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
