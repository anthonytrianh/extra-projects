Shader "Anthony/Mesh Light Decal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Color ("Color", Color) = (1,1,1,1)
        _Threshold ("Threshold", Range(0, 1)) = 0.01
        
        [Header(Attenuation)][Space]
        _LightParams ("Light Intensity Min Max", Vector) = (0.5, 1, 0, 0)
        _LightNoiseTiling ("Light Noise Tiling", Vector) = (1, 1, 0, 0)
        _LightNoiseParams ("Light Speed (XY) Density", Vector) = (1, 1, 1, 0)
    }
    
    CGINCLUDE
    #include "Decals.cginc"
	#include "GradientNoise.cginc"
    #include "ReconstructWorldPositionFromDepth.cginc"
    
    uniform sampler2D _CameraDepthNormalsTexture;

    float Unity_RandomRange_float(float2 Seed, float Min, float Max)
    {
        float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
        return lerp(Min, Max, randomno);
    }
    
    float _TimeOffset;
    float4 _LightParams;
    float4 _LightNoiseTiling;
    float4 _LightNoiseParams;
    
    fixed4 frag(v2f_decal i) : SV_Target
    {
        fixed4 color;

        float2 uv = ComputeDecalUv(i);
        color = tex2D(_MainTex, uv) * _Color * i.color;
        color.a = color.a * i.color.a * _Color.a;
        
        // 2nd way to do decals
        // Lighting
        float2 screenPosNormalized = i.screenPos.xy / i.screenPos.w;
        float cameraDepth;
        float3 cameraNormal;
        DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, screenPosNormalized), cameraDepth, cameraNormal);
        float3 worldNormal = mul(unity_MatrixInvV, float4( cameraNormal, 0)).xyz;

        // Light direction
        float3 pivot = float3(0, 0, 0);
        float3 pivotWorldPosition = mul(unity_ObjectToWorld, float4(pivot, 1)).xyz;
        // Reconstruct world pos from depth
        float3 worldPosFromDepth = ReconstructWorldPositionFromDepth(i.screenPos);
        float3 lightDirecton = normalize(pivotWorldPosition - worldPosFromDepth);

        float nDotL = saturate(dot(worldNormal, lightDirecton));

        // local space
        float3 localPos = mul(unity_WorldToObject, float4(worldPosFromDepth, 1)).xyz;
        localPos += 0.5;

        color = tex2D(_MainTex, localPos.xz) * _Color * i.color;
        color.a = color.a * i.color.a * _Color.a;

        // Atten
        float timeOffset = _TimeOffset;
        float noise =
            GradientNoise(float2(uv.x, 0) * _LightNoiseTiling.xy +
                (_Time.y + timeOffset) * _LightNoiseParams.xy,
                _LightNoiseParams.z);
        noise -= 0.5f;
        float lightIntensity = lerp(_LightParams.x, _LightParams.y, noise);
        color *= lightIntensity;
        
        return color * nDotL;
    }
    
    ENDCG
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent-400"
            "Queue"="Transparent+1" 
            "PreviewType"="Plane"
            "DisableBatching" = "True"
        }
        LOD 100
        
        Blend SrcAlpha One
        ZWrite Off
        ZTest GEqual
        Cull Front
        Lighting Off
        Offset -1,-1

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
       
            ENDCG
        }
    }
}
