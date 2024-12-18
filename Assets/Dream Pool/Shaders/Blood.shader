Shader "Anthony/Blood"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _SpecularColor ("Specular Color", Color) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
            "Queue" = "Transparent" 
        }
        LOD 200

        Blend SrcAlpha One
        ZWrite Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardSpecular fullforwardshadows alpha
        #pragma target 4.5

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        fixed4 _SpecularColor;
        fixed4 _Color;

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Specular = _SpecularColor * c.a;
            o.Smoothness = _Glossiness;
            o.Alpha = c.r;
        }
        ENDCG
    }
    FallBack "Transparent/VertexLit"
}
