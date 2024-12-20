#ifndef DECALS_INCLUDED
#define DECALS_INCLUDED


#include "UnityCG.cginc"
////////////////////////////////////////////////////////////
//                  Decal shader
//---------------------------------------------------------
//      Tags 
//        { 
//            "Queue" = "Transparent+1"
//            "RenderType"="Transparent-400"
//            "PreviewType" = "Plane"
//            "DisableBatching" = "True"
//        }
//
//        ZWrite Off
//        ZTest GEqual or Always
//        Cull Front
//        Offset -1,-1  // Sets the depth offset for this geometry so that the GPU draws this geometry closer to the camera
//                      // You would typically do this to avoid z-fighting
//---------------------------------------------------------

struct appdata
{
    float4 vertex       : POSITION;
    float4 normal       : NORMAL;
    fixed4 color        : COLOR;
};

struct v2f_decal
{
    float4 position     : SV_POSITION;
    float4 normal       : NORMAL;
    float4 screenPos    : TEXCOORD0;
    float3 ray          : TEXCOORD1;
    float3 worldPos     : TEXCOORD2;

    fixed4 color        : COLOR;
};

// Depth texture
sampler2D_float _CameraDepthTexture;

// Inputs
sampler2D   _MainTex;
float4      _MainTex_ST;
fixed4 _Color;
float _Threshold;

//--------------------------------------------------
//      Utils functions
//--------------------------------------------------
float3 ReconstructWorldPositionFromDepth_Decal(float2 screenPos, float3 worldRay)
{
    // Sample depth
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
    depth = Linear01Depth(depth) * _ProjectionParams.z;
    // Get normalized ray from the camera
    worldRay = normalize(worldRay);
    // The 3rd row of the view matrix has the camera forward vector encoded,
    // so a dot product with that will give the inverse distance in that direction
    worldRay /= dot(worldRay, -UNITY_MATRIX_V[2].xyz);
    // Reconstruct world and object space positions
    float3 worldPos = _WorldSpaceCameraPos + worldRay * depth;
    return worldPos;
}


// Computer projected positions
float3 GetProjectedObjectPos(float2 screenPos, float3 worldRay, out float3 worldPos)
{
    // Reconstruct world and object space positions
    worldPos = ReconstructWorldPositionFromDepth_Decal(screenPos, worldRay);
    float3 objectPos = mul(unity_WorldToObject, float4(worldPos, 1)).xyz;
        // Clip things behind in order to get the "decal" effect
    clip(0.5 - abs(objectPos));
        // -0.5|0.5 space to 0|1 for nice texture stuff if thats what we want
    objectPos += 0.5;
    return objectPos;
}

float2 ComputeDecalUv(v2f_decal i)
{
    float2 screenUv = i.screenPos.xy / i.screenPos.w;
    float3 worldPos;
    float3 objectPos = GetProjectedObjectPos(screenUv, i.ray, worldPos);
    float2 uv = objectPos.xz;
    return uv;
}

float2 ComputeDecalUv(float4 screenPos, float3 ray)
{
    float2 screenUv = screenPos.xy / screenPos.w;
    float3 worldPos;
    float3 objectPos = GetProjectedObjectPos(screenUv, ray, worldPos);
    float2 uv = objectPos.xz;
    return uv;
}

float3 ComputeWorldPositionDecal(float4 screenPos, float3 ray)
{
    float2 screenUv = screenPos.xy / screenPos.w;
    float3 worldPos;
    float3 objectPos = GetProjectedObjectPos(screenUv, ray, worldPos);
    return worldPos;
}

float2 ComputeWorldDecalUv(v2f_decal i)
{
    float3 worldPos = ComputeWorldPositionDecal(i.screenPos, i.ray);
    float2 uv = worldPos.xz;
    return uv;
}

float2 ComputeWorldDecalUv(float4 screenPos, float3 ray)
{
    float3 worldPos = ComputeWorldPositionDecal(screenPos, ray);
    float2 uv = worldPos.xz;
    return uv;
}

#define DECAL_SAMPLE_ALPHA(color, tex, st, input) \
    color = tex2D(_MainTex, ComputeDecalUv(input) * st.xy + st.zw) * _Color; \
    color.a = color.a * input.color.a * _Color.a; \

//----------------------------------------------------
//      Vert-frag
//----------------------------------------------------
// Vertex shader
v2f_decal vert(appdata v)
{
    v2f_decal o;
    // Compute world position
    float3 worldPos =  mul(unity_ObjectToWorld, v.vertex);
    // Clip space based on world position instead of object space position
    o.position = UnityWorldToClipPos(worldPos);
    // Calculate ray cast from camera to vert
    o.ray = worldPos - _WorldSpaceCameraPos;
    // Screen position
    o.screenPos = ComputeScreenPos(o.position);
    
    o.worldPos = worldPos;
    o.color = v.color;
    return o;
}

fixed4 fragAlpha(v2f_decal i) : SV_Target
{
    fixed4 color;

    DECAL_SAMPLE_ALPHA(color, tex, _MainTex_ST, i);
    float a = i.color.a * color.a;
    clip(a - _Threshold);
    
    return color;
}

#endif //DECALS_INCLUDED