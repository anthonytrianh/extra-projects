Shader "Anthony/Fake Light Decal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _ColorIn ("Color In", Color) = (1,1,1,1)
        [HDR] _ColorOut ("Color Out", Color) = (1,1,1,1)
        _ColorGradientContrast ("Color Gradient Contrast", Float) = 1
        _ColorGradientRamp ("Color Gradient Ramp", 2D) = "black" {}
        
        _Threshold ("Threshold", Range(0, 1)) = 0.01
        
        [Header(Attenuation)][Space]
        _LightParams ("Light Intensity Min Max", Vector) = (0.5, 1, 0, 0)
        _LightNoiseTiling ("Light Noise Tiling", Vector) = (1, 1, 0, 0)
        _LightNoiseParams ("Light Speed (XY) Density", Vector) = (1, 1, 1, 0)
        _LightFalloffStrength ("Light Falloff", Float) = 1
    }
    
    CGINCLUDE
    #include "Decals.cginc"
	#include "GradientNoise.cginc"
    #include "ReconstructWorldPositionFromDepth.cginc"
    
    uniform sampler2D _CameraDepthNormalsTexture;
    
    float _TimeOffset;
    float4 _LightParams;
    float4 _LightNoiseTiling;
    float4 _LightNoiseParams;
    float _LightFalloffStrength;

    float4 _ColorIn, _ColorOut;
    float _ColorGradientContrast;
    sampler2D _ColorGradientRamp;
    
    fixed4 frag(v2f_decal i) : SV_Target
    {
        fixed4 color;

        float2 uv = ComputeDecalUv(i);
        
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

        // Colors
        float3 localPos = mul(unity_WorldToObject, float4(worldPosFromDepth, 1)).xyz;
        float2 localUVs = localPos.xz + 0.5;

        // Calculate fall off
        float3 scaledLocalPos = localPos * 1.1f;
        float distance = saturate(1 - dot(scaledLocalPos, scaledLocalPos));
        float fallOff = distance * distance;
        fallOff = pow(fallOff, _LightFalloffStrength);

        // Light color
        float2 centeredUvs = localUVs * 2 - 1;
        float lightColorInterp = saturate(pow(length(centeredUvs), _ColorGradientContrast));
        float ramp = tex2D(_ColorGradientRamp, float2(lightColorInterp, 0));
        float4 lightColor = lerp(_ColorIn, _ColorOut, ramp);
        color = tex2D(_MainTex, localUVs) * lightColor * i.color;
        color.a = color.a * i.color.a * lightColor.a;
        color *= fallOff;

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
