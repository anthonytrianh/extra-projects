#ifndef WIND_INCLUDED
#define WIND_INCLUDED

#include "UnityCG.cginc"
#include "GradientNoise.cginc"

//--------------------------------------------
//  Wind Sway
//--------------------------------------------

// [Header(Wind)][Space]
// _WindScale ("Wind Scale", Vector) = (1, 1, 0, 0)
// _WindMovement ("Wind Movement", Vector) = (2, 1, 0, 0)
// _WindDensity ("Wind Density", Float) = 1
// _WindStrength ("Wind Strength", Float) = 0.5

float2 _WindScale;
float2 _WindMovement;
float _WindDensity;
float _WindStrength;

float WindSway(float3 position, float2 uv)
{
    ///////////////////////////
    // Wind
    //!! World Position must be manually calculated here, o.worldPos is not yet calculated at this stage
    float3 worldPosition = mul(unity_ObjectToWorld, position);
    float2 windUV = worldPosition.xy / _WindScale.xy + _Time.y * _WindMovement.xy;
    float noise = GradientNoise(windUV, _WindDensity);
    float wind = noise - 0.5;
    wind *= _WindStrength;
    wind *= uv.y;
    return wind;
}

#endif