#ifndef RAIN_INCLUDED
#define RAIN_INCLUDED

#include "UnityCG.cginc"

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

#endif