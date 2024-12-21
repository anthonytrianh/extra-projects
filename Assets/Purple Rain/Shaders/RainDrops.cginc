#ifndef RAINDROPS_INCLUDED
#define RAINDROPS_INCLUDED

#include "UnityCG.cginc"

//////////////////////////////////////////////
// Rain Drops

sampler2D _RainDropsTex;
float4 _RainDropsTex_ST;
float _RainDropsNormalStrength;
float _RainDropsAnimSpeed;
float _RainDropsAmount;
float _RainDropsSmoothnessPower;
float _RainDropsScale;

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
    float staticMask = saturate((rainDropsSample.a * 2 - 0.5) * (-1));

    // Final rain mask: combine static and animated
    float rainMask = animMask + staticMask;

    // Get world normal up to mask rain drops
    float topMask = saturate(worldNormal.y) * _RainDropsAmount;
    rainMask *= topMask;

    // Ouputs
    dropsNormal = float3(rainDropsNormalOffset * rainMask, 1);
    mask = rainMask * rain;
}

#endif