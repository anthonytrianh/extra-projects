#ifndef RAIN_INCLUDED
#define RAIN_INCLUDED

#include "UnityCG.cginc"
#include "Wetness.cginc"
#include "RainDrops.cginc"
#include "RainDrips.cginc"

/////////////////////////////////////////////
// Material Parameters
// -----------------------------------------
// [Header(RippleMain)][Space]
// _RipplesTex ("Ripples Texture", 2D) = "white" {}
// _RippleContrast ("Ripple Contrast", Float) = 20
// _RipplePeriod ("Ripple Period", Float) = 5
// _RippleStrength ("Ripple Strength", Float) = 0.35
// _RippleIntensity ("Ripple Intensity", Range(0, 1)) = 1
//         
// [Header(RippleParams)][Space]
// _RipplesTimeScales ("Ripples Time Scales", Vector) = (1, 0.8, 0.92, 1.1)
// _RipplesTimeOffsets ("Ripples Time Offsets", Vector) = (0, 0.2, 0.44, 0.67)
// _RipplesWeightOffsets ("Ripples Weight Offsets", Vector) = (0, 0.25, 0.5, 0.75)
// _RipplesTilings ("Ripples Tilings", Vector) = (20, 10, 5, 2)
//         
// [Header(RippleOffsets)][Space]
// _RipplesOffset1 ("Ripple Offset 1", Vector) = (0, 0, 0, 0)
// _RipplesOffset2 ("Ripple Offset 2", Vector) = (-0.5, 0.3, 0, 0)
// _RipplesOffset3 ("Ripple Offset 3", Vector) = (0.44, 0.8, 0, 0)
// _RipplesOffset4 ("Ripple Offset 4", Vector) = (0.55, -0.7, 0, 0)
//         
// [Header(RippleWind)][Space]
// _WindRippleTex ("Wind Ripples Texture", 2D) = "bump" {}
// _WindRippleParams1 ("Wind Ripples 1 Tiling (XY) Speed (ZW)", Vector) = (20, 17, .4, .02)
// _WindRippleParams2 ("Wind Ripples 2 Tiling (XY) Speed (ZW)", Vector) = (5, 8, -.1, .4)
// _WindRippleStrength ("Wind Strength Min Max", Vector) = (0.1, 0.5, 0, 0)
// _WindRipple ("Wind Ripples", Range(0, 1)) = 1
// _WindRippleOpacity ("Wind Ripple Opacity", Range(0, 1)) = 1

/////////////////////////////////////////////
//  Rain
//------------------------------------------
float _Rain;

/////////////////////////////////////////////
// Rain Ripple

// Ripple Core
uniform sampler2D _RipplesTex;
float _RipplesUvScale;
float _RippleContrast;
float _RipplePeriod;
float _RippleStrength;
float _RippleIntensity;

// Ripple Layers
float4 _RipplesTimeScales;
float4 _RipplesTimeOffsets;
float4 _RipplesWeightOffsets;
float4 _RipplesTilings;

float4 _RipplesOffset1;
float4 _RipplesOffset2;
float4 _RipplesOffset3;
float4 _RipplesOffset4;

inline float4 SampleRipple(float2 uv, float scale, float2 offset)
{
    return tex2D(_RipplesTex, uv * scale + offset);
}

inline float3 RainRipples(float4 rippleSample, float time, float weight = 1, float contrast = 20, float period = 4, float strength = 0.35)
{
    // Temporal offset: stored in A channel of texture (or use custom texture)
    float rippleTime = time + rippleSample.a;
    // Ripple lifetime
    float lifeTime = frac(rippleTime);
    // Remap time offset to (-1, 0) for ripples to fade in from (0 -> 1)
    float timeOffset = lifeTime - 1;
    // Fade in ripple opacity using timeOffset
    float ripple = rippleSample.r + timeOffset;
    // Contrast adjust
    ripple *= contrast;
    // Clamp ripple between (0, ripples count)
    ripple = clamp(ripple, 0, period);
    // Multiply by pi
    ripple *= UNITY_PI;
    // Create ripple
    ripple = sin(ripple);
    // // Fade out ripple
    //     float rippleOpacityOverLifetime = 1 - lifeTime;
    // Weight-based fade out
    float rippleOpacityOverLifetime = saturate(weight * 0.8 + 0.2 - lifeTime);
    ripple *= rippleOpacityOverLifetime;
    // Ripple normals xy stored in sample's G and B channels
    float2 rippleNormalXY = rippleSample.gb * 2 - 1;
    // Apply ripple mask
    rippleNormalXY *= ripple;
    // Apply ripple strength
    rippleNormalXY *= strength;
    // Append 1 on Z to make normal vector from ripple
    float3 rippleNormal = float3(rippleNormalXY, 1);
    // Output
    return rippleNormal;
}

inline float3 RainRippleLayer(float2 uv, float scale = 1, float2 offset = 0, float timeScale = 1, float timeOffset = 0, float weightOffset = 0, float layerCount = 4)
{
    float4 ripples = SampleRipple(uv, 1 / scale, offset);
    float2 time = _Time.y * timeScale + timeOffset;
    float weight = (_RippleIntensity - weightOffset) * layerCount;
    weight = saturate(weight);
    return RainRipples(ripples, time, weight, _RippleContrast, _RipplePeriod, _RippleStrength);
}

inline float3 BlendRipplesNormals4(float4 weights, float3 normal1, float3 normal2, float3 normal3, float3 normal4)
{
    // Combine RG
    float2 combinedRG = normal1.rg + normal2.rg + normal3.rg + normal4.rg;
    // Combine B
    float4 z = float4(normal1.b, normal2.b, normal3.b, normal4.b);
    z = lerp(1, z, weights);
    float normalZ = z.x * z.y * z.z * z.w;
    // Final normal
    return normalize(float3(combinedRG, normalZ));
}

/////////////////////////////////////////////
// Wind Ripple

sampler2D _WindRippleTex;
float4 _WindRippleParams1;
float4 _WindRippleParams2;
float2 _WindRippleStrength;
float _WindRipple;
float _WindRippleOpacity;

inline float3 CalculateWindRippleNormal(float2 worldUV, float4 windParams)
{
    float2 windRippleUV = worldUV / windParams.xy + _Time.y * windParams.zw;
    return UnpackNormal(tex2D(_WindRippleTex, windRippleUV));
}

inline float3 WindRipple(float2 worldUV)
{
    float3 windNormal1 = CalculateWindRippleNormal(worldUV, _WindRippleParams1);
    float3 windNormal2 = CalculateWindRippleNormal(worldUV, _WindRippleParams2);

    float wind = lerp(_WindRippleStrength.x, _WindRippleStrength.y, _WindRipple);
    // Blend wind normals
    float2 normalXY = windNormal1.xy + windNormal2.xy;
    normalXY *= wind;
    float normalZ = windNormal1.z * windNormal2.z;
    float3 windRipplesNormal = normalize(float3(normalXY, normalZ));
    return lerp(float3(0, 0, 1), windRipplesNormal, _WindRippleOpacity);
}

#endif