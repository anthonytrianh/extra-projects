#ifndef WETNESS_INCLUDED
#define WETNESS_INCLUDED

//////////////////////////////////////////////
// Rain Wetness
float _WetnessSaturation;
float _WetnessColorDarken;
float _Wetness;
float _Porousness;

float3 Saturation(float3 color, float saturation)
{
    // Greyscale to get luminosity
    float luma = dot(color, float3(0.2126729, 0.7151522, 0.0721750));
    return luma.xxx + saturation.xxx * (color - luma.xxx);
}

// Wet surfaces have more saturated and darker colors
float3 CalculateWetColor(float3 color)
{
    float3 baseColor = color;
    float3 wetColor = saturate(Saturation(color, _WetnessSaturation)) * _WetnessColorDarken;
    float absorption = _Wetness * _Porousness;
    return lerp(baseColor, wetColor, absorption);
}

// Water has roughness of 0.07
float CalculateWetSmoothness(float smoothness)
{
    return lerp(smoothness, 1 - 0.07, _Wetness);
}

// Water has lower specular than common materials (0.3), base specular is 0.5
float CalculateWetSpecular(float specular)
{
    return lerp(specular, 0.3, _Wetness);
}

#endif