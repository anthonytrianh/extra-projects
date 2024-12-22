#ifndef RAINDRIPS_INCLUDED
#define RAINDRIPS_INCLUDED

#include "UnityCG.cginc"

// [Header(Raindrops)][Space]
// _RainDripsTex ("Rain Drips Texture", 2D) = "bump" {}
// _RainDripsWorldScale ("Rain Drips World Scale", Float) = 1
// _RainDripMask ("Rain Drip Mask", 2D) = "black" {}
// _RainDripMaskScale ("Rain Drip Mask Scale", Vector) = (1, 1.05, 1, 0)
// _RainDripsSpeedFast ("Rain Drip Speed Min Max", Vector) = (0.25, 0.7, 0, 0)
// _RainDripsSpeedSlow ("Rain Drip Speed Min Max", Vector) = (0.03, 0.125, 0, 0)
// _RainSurfacePermeable ("Rain Surface Permeability", Range(0, 1)) = 0.3
// _RainDripsStrength ("Rain Drips Strength", Float) = 1
// _RainDripsSmoothnessContrast ("Rain Drips Smoothness Contrast", Float) = 1.2


//////////////////////////////////////////////
// Rain Drips

sampler2D _RainDripsTex;
float _RainDripsWorldScale;
sampler2D _RainDripMask;
float4 _RainDripMaskScale;
float4 _RainDripsSpeedFast;
float4 _RainDripsSpeedSlow;
float _RainSurfacePermeable;
float _RainDripsStrength;
float _RainDripsSmoothnessContrast;

void RainDrips(float3 worldPos, float3 worldNormal, out float3 normal, out float mask, float porousness = 0.5, float rain = 1)
{
    //----------------------------------
    // Rain drips
    //----------------------------------
    // Triplanar project using world position            
    float3 rainDripWorldPos = worldPos * _RainDripsWorldScale;

    float3 scaledWorldPosSide = rainDripWorldPos * float3(1, 0.5, -1);
    float3 scaledWorldPosFront = rainDripWorldPos * float3(-1, -0.5, -1);

    float sideAlpha = saturate(sign(worldNormal)).r;
    float frontAlpha = saturate(sign(worldNormal)).b;

    float3 frontBlend   = lerp(scaledWorldPosSide, scaledWorldPosFront, frontAlpha);
    float3 sideBlend    = lerp(scaledWorldPosFront, scaledWorldPosSide, sideAlpha);

    float2 rainDripFront    = frontBlend.xy;
    float2 rainDripSide     = sideBlend.zy;

    float viewMask = round(abs(worldNormal)).r; // Looking from the front or the side
    float2 rainDripsUV = lerp(rainDripFront, rainDripSide, viewMask);

    // Sample drips texture
    float4 dripsSample = tex2D(_RainDripsTex, rainDripsUV);

    // Temporal offset mask contained in dripsSample alpha
    float temporalOffset = dripsSample.a;
    float timeOffset = _Time.y + temporalOffset;

    // Drips mask contained in blue channel
    float dripsMaskBase = dripsSample.b;
    
    // Round the mask so the drops looks more condensed
    float dripsMaskFast = round(dripsMaskBase);
    float3 dripsFast = float3(dripsMaskFast, _RainDripsSpeedFast.xy);
    float3 dripsSlow = float3(dripsMaskBase, _RainDripsSpeedSlow.xy);
    float3 dripsMovement = lerp(dripsFast, dripsSlow, porousness);

    float permeability = lerp(dripsMovement.y, dripsMovement.z, temporalOffset); 
    timeOffset *= permeability;

    float dripsMask = dripsMovement.x;

    // Animated mask
    float2 rainDripMaskUV = (rainDripWorldPos * _RainDripMaskScale.xyz).xy;
    rainDripMaskUV += timeOffset;
    float drips = tex2D(_RainDripMask, rainDripMaskUV).r;
    drips *= dripsMask;

    // Vertical mask
    float sideMask = saturate(abs(worldNormal.y));
    sideMask = lerp(3.5, -1.5, sideMask);

    // Offset Normals
    float2 dripsNormalOffset = (dripsSample.xy * 2 - 1) * drips * _RainDripsStrength * sideMask;
    float3 dripsNormals = float3(dripsNormalOffset, 1);

    // Output
    normal = dripsNormals;
    mask = drips * rain;
    
}

#endif