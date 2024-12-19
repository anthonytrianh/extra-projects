Shader "Anthony/Surface/RGB Standard Roughness Metallic Normals"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        [Header(Metallic)][Space]
        _MetallicTex("Metallic Map", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [Header(Roughness)][Space]
        _RoughnessTex("Roughness Map", 2D) = "black" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5

        [Header(Normals)][Space]
        _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpStrength("Bump Strength", Float) = 1

        [Header(Emission)][Space]
        [Toggle(EMISSIVE)] _Emission ("Emission?", Float) = 0
        _EmissiveTex("Emission Texture", 2D) = "black" {}
        [HDR] _EmissiveColor("Emissive Color", Color) = (0, 0, 0, 0)

        [Header(HeightParallax)][Space]
        [Toggle(_PARALLAX)] _UseParallax("Height?", Int) = 0
        [NoScaleOffset] _ParallaxTex("Height Tex", 2D) = "white" {}
        _Height("Height", Float) = 0

        [Toggle(FLIP_V)] _FlipY("Flip Y?", Float) = 0

        [Toggle(VERT_GRADIENT)] _VerticalGradient ("Veritcal Gradient Color?", Float) = 0
        _ColorTop ("Color Top", Color) = (1,1,1,1)
        _ColorBot ("Color Bottom", Color) = (0.5, 0.5, 0.5, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma shader_feature EMISSION
        #pragma shader_feature FLIP_V
        #pragma shader_feature _PARALLAX
        #pragma shader_feature VERT_GRADIENT

        #pragma target 3.0

        #include "RGBShadersShared.cginc"

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float3 viewDir;
            float3 objPos;
        };

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        sampler2D _RoughnessTex;
        sampler2D _MetallicTex;

        // Parallax
        sampler2D _ParallaxTex;
        float _Height;

        // Vertical Gradient
        float4 _ColorTop, _ColorBot;

        float2 GetParallaxOffset(sampler2D parallaxTex, float2 uv, float height, float3 viewDir)
        {
            float parallaxSample = tex2D(parallaxTex, uv).r;
            return ParallaxOffset(parallaxSample, height, viewDir);
        }

        void vert(inout appdata_full v, out Input o) 
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.objPos = v.vertex;
            o.objPos.y = (v.vertex.y + 1) * 0.5;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.uv_MainTex;
#if FLIP_V
            uv.y = 1 - uv.y;
#endif

#ifdef _PARALLAX
            uv += GetParallaxOffset(_ParallaxTex, uv, _Height, IN.viewDir);
#endif

            fixed4 c;

            float4 shading = _Color;
#if VERT_GRADIENT
            shading = lerp(_ColorTop, _ColorBot, 1 - IN.objPos.y);
#endif

            // Albedo comes from a texture tinted by color
            c = tex2D(_MainTex, uv) * shading;
            
            float roughness = tex2D(_RoughnessTex, uv);
            float metal = tex2D(_MetallicTex, uv);

            o.Albedo = c.rgb;
            o.Metallic = metal * _Metallic;
            o.Smoothness = (1 - roughness) * _Glossiness;
            o.Alpha = c.a;

            o.Normal = UnpackScaleNormal(tex2D(_BumpTex, uv), _BumpStrength);

            o.Emission = tex2D(_EmissiveTex, uv) * _EmissiveColor;

            //o.Albedo = IN.viewDir;
                //GetParallaxOffset(_ParallaxTex, uv, _Height, IN.viewDir).xxx;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
