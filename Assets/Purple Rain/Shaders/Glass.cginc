#ifndef GLASS_INCLUDED
#define GLASS_INCLUDED

#include "UnityCG.cginc"

/////////////////////////////////////////
/// Properties

// Glass
struct Input
{
    float2 uv_MainTex;
    float3 worldPos;
    float3 worldNormal; INTERNAL_DATA
    float3 viewDir;
    float4 screenPos;
    float3 objectNormal;

    // float3 worldTangent;
    // float3 wNormal;
    // float3 worldBitangent;
};
    
float _IOR;
float _Opacity;
float _Reflectivity;

uniform sampler2D _BackgroundTex;

float3 RefractionDirection(float3 viewDir, float3 normal, float indexOfRefraction)
{
    return refract(normalize(viewDir), normalize(normal), 1.0 / indexOfRefraction);
}

void vert_glass(inout appdata_full v, out Input o) 
{
    UNITY_INITIALIZE_OUTPUT(Input, o);
    o.objectNormal = normalize(mul(float4(v.normal, 0), unity_WorldToObject).xyz);
    // float3 worldTangent = UnityObjectToWorldDir(v.tangent);
    // o.worldTangent.xyz = worldTangent;
    // float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    // o.wNormal.xyz = worldNormal;
    // float vertexTangentSign = v.tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
    // float3 worldBitangent = cross(worldNormal, worldTangent ) * vertexTangentSign;
    // o.worldBitangent.xyz = worldBitangent;
}

float3 FragmentGlassColor(Input i, float3 normal)
{
    float4 screenPos = i.screenPos;
    float3 refractionDir = RefractionDirection(i.viewDir, normal, _IOR);
    
    // float3 worldTangent = i.worldTangent.xyz;
    // float3 worldNormal = i.worldNormal.xyz;
    // float3 worldBitangent = i.worldBitangent.xyz;
    // float3x3 worldToTangent = float3x3(worldTangent, worldBitangent, worldNormal);
    // float3 worldToTangentDir = mul( worldToTangent, refractionDir)

    screenPos.xyz += refractionDir;
            
    // Sample background texture
    float2 screenUV = screenPos.xy / screenPos.w;
    float3 backgroundColor = tex2D(_BackgroundTex, screenUV);
    return backgroundColor * _Reflectivity;
}

#endif