Shader "Custom/KatanaWire"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        [Header(Emission)][Space]
        _EmissiveTex ("Emissive Tex", 2D) = "black" {}
        [HDR] _EmissiveColorTop ("Emissive Color Top", Color) = (1,1,1,1)
        [HDR] _EmissiveColorBot ("Emissive Color Bottom", Color) = (0, 0, 0, 1)
        _LineSpeed ("Line Speed", Float) = 1
        _Flicker ("Min Max Flicker (XY), Speed (Z)", Vector) = (0.95, 1.05, 1, 0)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 4.0

	    #include "UnityCG.cginc"
		#include "ShaderMaths.cginc"
        
        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        struct Input
        {
            float2 uv_MainTex;
        };

        sampler2D _EmissiveTex;
        float4 _EmissiveColorTop;
        float4 _EmissiveColorBot;
        float _LineSpeed;
        float4 _Flicker;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            // Emissive
            float4 emissiveColor = tex2D(_EmissiveTex, IN.uv_MainTex + float2(0, _LineSpeed) * _Time.y);
            emissiveColor *= lerp(_EmissiveColorBot, _EmissiveColorTop, IN.uv_MainTex.y);
            fixed4 flicker = lerp(_Flicker.x, _Flicker.y, rand2(_Time.x * _Flicker.z));
            emissiveColor.rgb *= flicker;
            o.Emission = emissiveColor;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
