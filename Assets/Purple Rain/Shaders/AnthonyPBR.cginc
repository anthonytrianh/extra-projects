#ifndef ANTH_PBR
#define ANTH_PBR

#include "PBRCommons.cginc"

/////////////////////////////////////////
/// Properties

struct Input
{
    float2 uv_MainTex;
    float3 worldPos;
    float3 worldNormal; INTERNAL_DATA
    float3 viewDir;
    float3 objPos;
    float4 screenPos;
    float3 debug;
};

// Vertical Gradient
float4 _VerticalColorTop;
float4 _VerticalColorBot;

#pragma shader_feature FLIP_V
float2 CalculateUv(Input i)
{
    float2 uv = i.uv_MainTex;
    #if FLIP_V
    uv.y = 1 - uv.y;
    #endif
    return uv;
}

#pragma shader_feature VERTICAL_GRADIENT
float4 CalculateColorVerticalGradient(Input i)
{
    return lerp(_VerticalColorTop, _VerticalColorBot, 1 - i.objPos.y);
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