#ifndef RAINDROPS_INCLUDED
#define RAINDROPS_INCLUDED

#include "UnityCG.cginc"

// [Header(Raindrops)][Space]
// _RainDropsTex ("Rain Drops Texture", 2D) = "bump" {}
// _RainDropsScale ("Rain Drops Scale", Float) = 1
// _RainDropsNormalStrength ("Rain Normal Strength", Float) = 2
// _RainDropsAnimSpeed ("Rain Drops Animation Speed", Float) = 0.7
// _RainDropsAmount ("Rain Drops Amount", Range(0, 1)) = 1
// _RainDropsSmoothnessPower ("Rain Drops Smoothness Power", Float) = 0.1


//////////////////////////////////////////////
// Rain Drops

sampler2D _RainDropsTex;
float4 _RainDropsTex_ST;
float _RainDropsNormalStrength;
float _RainDropsAnimSpeed;
float _RainDropsAmount;
float _RainDropsSmoothnessPower;
float _RainDropsScale;

sampler2D _RainDropsMeshMask;
float2 rainDropsMeshUVs; 

void RainDrops(float3 worldPos, float3 worldNormal, out float3 dropsNormal, out float mask, float rain = 1)
{
    float2 uv = worldPos.xz * _RainDropsScale;
    
    // 1. Animated rain drops
    float4 rainDropsSample = tex2D(_RainDropsTex, uv * _RainDropsTex_ST.xy + _RainDropsTex_ST.zw);
    // Normal: Unpack rg channels and remap from (0,1) to (-1,1)
    float2 rainDropsNormalOffset = (rainDropsSample.xy * 2 - 1) * _RainDropsNormalStrength;
    // Animation: blue channel contains temporal offset mask
    float rainDropsTime = (_Time.y * _RainDropsAnimSpeed) - rainDropsSample.b;
    rainDropsTime = frac(rainDropsTime);
    // Animated drop mask in alpha channel
    float animMask = saturate(rainDropsSample.a * 2 - 1) * rainDropsTime;

    // 2. Static rain drops
    // Invert alpha channel for static rain drops
    float staticMask = saturate(pow((rainDropsSample.a * 2 - 0.5) * (-1), _RainDropsAmount));

    // Final rain mask: combine static and animated
    float rainDropsFinalMask = animMask + staticMask;

    // Get world normal up to mask rain drops
    float topMask = saturate(worldNormal.y) * rain;
    rainDropsFinalMask *= topMask;
    // Mesh mask (some faces should have rain drops and some should not)
    float meshMask = tex2D(_RainDropsMeshMask, rainDropsMeshUVs);
    rainDropsFinalMask *= meshMask;
    
    // Ouputs
    dropsNormal = float3(rainDropsNormalOffset * rainDropsFinalMask, 1);
    mask = rainDropsFinalMask;
}

#endif