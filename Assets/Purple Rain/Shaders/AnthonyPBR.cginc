#ifndef ANTH_PBR
#define ANTH_PBR

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"

/////////////////////////////////////////
/// Properties

struct Input
{
    float2 uv_MainTex;
    float3 worldPos;
    float3 worldNormal; INTERNAL_DATA
    float3 viewDir;
    float3 objPos;
    float3 debug;
};

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

// Vertical Gradient
float4 _VerticalColorTop;
float4 _VerticalColorBot;

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

#pragma shader_feature FLIP_V
float2 CalculateUv(Input i)
{
    float2 uv = i.uv_MainTex;
    #if FLIP_V
        uv.y = 1 - uv.y;
    #endif
    return uv;
}

#pragma shader_feature PARALLAX
float2 GetParallaxOffset(float2 uv, float height, float3 viewDir)
{
    float parallaxSample = tex2D(_ParallaxTex, uv).r;
    return ParallaxOffset(parallaxSample, height, viewDir);
}

#pragma shader_feature VERTICAL_GRADIENT
float4 CalculateColorVerticalGradient(Input i)
{
    return lerp(_VerticalColorTop, _VerticalColorBot, 1 - i.objPos.y);
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
    return UnpackScaleNormal(tex2D(_BumpTex, uv), _BumpStrength);
}

float3 ComputeObjectPosition_Vertex(float3 vertex)
{
    // Compute local object's y position, used for vertical gradient
    return float3(vertex.x, (vertex.y + 1) * 0.5, vertex.z);
}

/////////////////////////////////////////
/// Standard PBR functions
void vert_pbr(inout appdata_full v, out Input o) 
{
    UNITY_INITIALIZE_OUTPUT(Input, o);
    o.objPos = ComputeObjectPosition_Vertex(v.vertex);
}

void surf_pbr_opaque(Input i, inout SurfaceOutputStandard o)
{
    APBR_uv(i);
    float parallax = GetParallaxOffset(uv, _Height, i.viewDir);
    #ifdef PARALLAX
    uv += parallax;
    #endif

    APBR_Albedo(o, uv);
    APBR_Metal(o, uv);
    APBR_Smoothness(o, uv);
    APBR_Normal(o, uv);
    APBR_Emission(o, uv);
    APBR_Alpha(o, color);
}

#endif