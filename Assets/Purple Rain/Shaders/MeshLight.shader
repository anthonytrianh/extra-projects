Shader "Anthony/Mesh Light"
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
    #include "UnityCG.cginc"
	#include "GradientNoise.cginc"

    UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
    uniform sampler2D _CameraDepthNormalsTexture;

    float Unity_RandomRange_float(float2 Seed, float Min, float Max)
    {
        float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
        return lerp(Min, Max, randomno);
    }

    struct appdata
    {
        float4 vertex       : POSITION;
        float4 normal       : NORMAL;
        fixed2 texcoord     : TEXCOORD0;
        fixed4 color        : COLOR;
    };
    
    struct v2f
    {
        float4 vertex       : SV_POSITION;
        float4 normal       : NORMAL;
        float2 uv           : TEXCOORD0;
        float4 screenPos    : TEXCOORD1;
        fixed4 color        : COLOR;
    };

    sampler2D _MainTex;
    float4 _MainTex_ST;

    fixed4 _Color;
    
    float _TimeOffset;
    float4 _LightParams;
    float4 _LightNoiseTiling;
    float4 _LightNoiseParams;

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

    v2f vert(appdata v)
    {
        v2f o;
        o.vertex    = UnityObjectToClipPos(v.vertex);
        o.normal    = v.normal;
        o.uv        = TRANSFORM_TEX(v.texcoord, _MainTex);
        // Screen position
        o.screenPos = ComputeScreenPos(o.vertex);
        o.color     = v.color;
        return o;
    }
    
    fixed4 frag(v2f i) : SV_Target
    {
        fixed4 color;

        float2 uv = i.uv;
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
