#ifndef RECONSTRUCT_WORLD_FROM_DEPTH_INCLUDED
#define RECONSTRUCT_WORLD_FROM_DEPTH_INCLUDED

float3 ReconstructWorldPositionFromDepth(float4 screenPos)
{
    float4 screenPosNormalized = screenPos / screenPos.w;
    screenPosNormalized.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNormalized.z : screenPosNormalized.z * 0.5 + 0.5;
    float2 screenUV = screenPosNormalized.xy;

    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
    #ifdef UNITY_REVERSED_Z
    float depthZ = 1.0 - depth;
    #else
    float depthZ = depth;
    #endif
    float3 depthNormalized = float3(screenUV.x, screenUV.y, depthZ);
    float3 depthVector = (depthNormalized * 2.0 - 1.0);
    float4 invertProjDepth = mul(unity_CameraInvProjection, float4(depthVector, 1));
    float3 invertProjDepthNormalized = invertProjDepth.xyz / invertProjDepth.w;
    float3 invertedDepthDirection = invertProjDepthNormalized * float3(1,1,-1);
    float3 worldPosition = mul(unity_CameraToWorld, float4(invertedDepthDirection, 1)).xyz;
    return worldPosition;
}

#endif