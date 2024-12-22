#ifndef PBR_COMMONS_INCLUDED
#define PBR_COMMONS_INCLUDED

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"

// Albedo
sampler2D _MainTex;
half4 _Color;

// Emission
sampler2D _EmissiveTex;
float4 _EmissiveTex_ST;
float4 _EmissiveColor;

// Metallic
sampler2D _MetallicTex;
half _Metallic;

// Roughness
sampler2D _RoughnessTex;
half _Glossiness;

// Specular
half _Specular;

// Normals
sampler2D _BumpTex;
float4 _BumpTex_ST;
float _BumpStrength;

// Parallax (height)
sampler2D _ParallaxTex;
float _Height;

/////////////////////////////////////////
/// Calculation functions

#define APBR_uv(i) float2 uv = CalculateUv(i);
#define APBR_Albedo(o, uv) float4 color = CalculateAlbedo(uv); \
                            o.Albedo = CalculateAlbedo(uv);
#define APBR_Alpha(o, color) o.Alpha = color.a;
#define APBR_Metal(o, uv) o.Metallic = CalculateMetallic(uv);
#define APBR_Smoothness(o, uv) o.Smoothness = CalculateSmoothness(uv);
#define APBR_Normal(o, uv) o.Normal = CalculateNormals(uv);
#define APBR_Emission(o, uv) o.Emission = CalculateEmissiveColor(uv);

#pragma shader_feature PARALLAX
float2 GetParallaxOffset(float2 uv, float height, float3 viewDir)
{
    float parallaxSample = tex2D(_ParallaxTex, uv).r;
    return ParallaxOffset(parallaxSample, height, viewDir);
}

float4 CalculateAlbedo(float2 uv)
{
    float4 albedo = tex2D(_MainTex, uv);
    float4 tint = _Color;
    #if VERTICAL_GRADIENT
        tint = CalculateColorVerticalGradient(i);
    #endif

    return albedo * tint;
}

float CalculateMetallic(float2 uv)
{
    float metallic =  tex2D(_MetallicTex, uv) * _Metallic;
    return metallic;
}

float CalculateSmoothness(float2 uv)
{
    float roughness = tex2D(_RoughnessTex, uv);
    return (1 - roughness) * _Glossiness;
}

float3 CalculateEmissiveColor(float2 uv)
{
    return tex2D(_EmissiveTex, uv) * _EmissiveColor;
}

float3 CalculateNormals(float2 uv)
{
    return UnpackScaleNormal(tex2D(_BumpTex, uv * _BumpTex_ST.xy + _BumpTex_ST.zw), _BumpStrength);
}

float3 ComputeObjectPosition_Vertex(float3 vertex)
{
    // Compute local object's y position, used for vertical gradient
    return float3(vertex.x, (vertex.y + 1) * 0.5, vertex.z);
}

#endif