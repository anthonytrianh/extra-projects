Shader "Anthony/Candle2"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        [Header(Candle)][Space]
        [HDR] _EmissiveColor ("Emissive Color", Color) = (1,1,0,1)
        _RampTex ("Candle Color Ramp", 2D) = "white" {}
        _CandleContrast ("Candle Contrast", Float) = 1
    }
    CGINCLUDE
    #include "AnthonyPBR.cginc"

    sampler2D _RampTex;
    float _CandleContrast;
    
    ENDCG
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert_pbr
        #pragma target 4.0
        
        void surf (Input i, inout SurfaceOutputStandard o)
        {
            o.Albedo = _Color;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1;

            // Candle colors
            float ramp = tex2D(_RampTex, i.uv_MainTex.y).r;
            o.Emission = pow(ramp, _CandleContrast) * _EmissiveColor;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
