Shader "Custom/Ocean Iris"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        _Cutoff ("Cutoff", Range(0, 1)) = 0
        _OpacityRadius ("Opacity Radius", Range(0, 1)) = 1
        _OpacitySmoothness ("Opacity Smoothness", Range(0, 0.5)) = 0.02
        _OpacityRadialPower ("Radial Opacity Power", Float) = 2
        
        _Stencil ("Stencil Mask", Float) = 2
    }
    CGINCLUDE

    #include "UnityCG.cginc"
    
    struct Input
    {
        float2 uv_MainTex;
    };

    sampler2D _MainTex;
    half _Glossiness;
    half _Metallic;
    fixed4 _Color;
    
    float _OpacityRadius;
    float _OpacitySmoothness;
    float _OpacityRadialPower;

    ENDCG
    SubShader
    {
        Stencil
        {
            Ref [_Stencil]
            Comp Always
            Pass Replace
        }

        Tags 
        { 
            "Queue" = "AlphaTest"
            "RenderType"="TransparentCutout" 
        }
        LOD 200

        CGPROGRAM
       
        #pragma surface surf Standard fullforwardshadows alphatest:_Cutoff

        #pragma target 4.0

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, i.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            // o.Alpha = c.a;

            // Cutout
            float2 centeredUVs = i.uv_MainTex * 2 - 1;
            float dist = length(centeredUVs);
            float mask = pow(dist, _OpacityRadialPower);
            float radialMask = 1 - smoothstep(_OpacityRadius, _OpacityRadius + _OpacitySmoothness, mask);
            //clip(radialMask - _Cutoff);
            o.Alpha = radialMask;
        }
        ENDCG
    }
    FallBack "Transparent/Cutout/VertexLit"
}
