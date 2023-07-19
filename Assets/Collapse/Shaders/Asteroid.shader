Shader "Custom/Asteroid"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        [Header(Metallic)][Space]
        _MetallicTex("Metallic Map", 2D) = "white" {}
        _Metallic("Metallic", Range(0,1)) = 0.0

        [Header(Roughness)][Space]
        _RoughnessTex("Roughness Map", 2D) = "black" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5

         [Header(Normals)][Space]
        _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpStrength("Bump Strength", Float) = 1

        [Header(HeightParallax)][Space]
        [Toggle(_PARALLAX)] _UseParallax("Height?", Int) = 0
        [NoScaleOffset] _ParallaxTex("Height Tex", 2D) = "white" {}
        _Height("Height", Float) = 0

        [Header(Asteroid)][Space]
        _EmberMask("Ember Mask", 3D) = "white" {}
        _EmberMaskScale ("Ember Mask Scale", Float) = 1
        _EmberMaskCutoff ("Ember Mask Cutoff", Range(0, 1)) = 0
        _EmberMaskSmoothness("Ember Mask Smoothness", Range(0, 1)) = 0.1

        _NoiseTex ("Noise Texture 3D", 3D) = "black" {}
        _NoiseScale ("Noise Scale", Float) = 1
        _NoiseCutoff ("Noise Cutoff", Range(0, 1)) = 0
        _NoiseSmoothness ("Noise Smoothness", Range(0, 1)) = 0.05
        _ColorRamp ("Color Ramp", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 1, 1)
        [NoScaleOffset] _EmissionRamp("Emission Color Ramp", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 4.0

        #pragma shader_feature _PARALLAX


        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float3 worldNormal; INTERNAL_DATA
            float3 objectPos;
            #ifdef _PARALLAX
                        float3 viewDir;
            #endif
        };

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        sampler3D _NoiseTex;
        float _NoiseScale;
        float _NoiseCutoff;
        float _NoiseSmoothness;
        sampler2D _ColorRamp;
        float4 _EmissionColor;
        sampler2D _EmissionRamp;

        sampler3D _EmberMask;
        float4 _EmberMask_ST;
        float _EmberMaskScale;
        float _EmberMaskCutoff;
        float _EmberMaskSmoothness;

        sampler2D _BumpTex;
        float _BumpStrength;
        sampler2D _RoughnessTex;
        sampler2D _MetallicTex;

        // Parallax
        sampler2D _ParallaxTex;
        float _Height;

        float2 GetParallaxOffset(sampler2D parallaxTex, float2 uv, float height, float3 viewDir)
        {
            float parallaxSample = tex2D(parallaxTex, uv).r;
            return ParallaxOffset(parallaxSample, height, viewDir);
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            o.objectPos = normalize(v.vertex.xyz) * 0.5 + 0.5;
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

            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, uv) * _Color;
            o.Albedo = c.rgb;

            float metal = tex2D(_MetallicTex, uv);
            o.Metallic = metal * _Metallic;

            float roughness = tex2D(_RoughnessTex, uv);
            o.Smoothness = (1 - roughness) * _Glossiness;

            o.Normal = UnpackScaleNormal(tex2D(_BumpTex, uv), _BumpStrength);

            o.Alpha = c.a;

            // Embers
            float noise = tex3D(_NoiseTex, IN.objectPos * _NoiseScale);
            noise = saturate(smoothstep(_NoiseCutoff + _NoiseSmoothness, _NoiseCutoff, noise));
            noise = pow(noise, 2);  

            float ramp = tex2D(_ColorRamp, float2(1 - noise, 0));
            ramp = min(ramp, 0.999);
            
            float emberMask = tex3D(_EmberMask, IN.objectPos * _EmberMaskScale + _EmberMask_ST.xyz).r;
            emberMask = smoothstep(_EmberMaskCutoff, _EmberMaskCutoff - _EmberMaskSmoothness, emberMask);
            ramp = noise;
            ramp *= emberMask;

            float3 embersColor = tex2D(_EmissionRamp, float2(1 - noise, 0));
            o.Emission = ramp * embersColor * _EmissionColor;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
