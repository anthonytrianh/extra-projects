Shader "Anthony/Liquids/Curry"
{
    Properties
    {
        [Header(Water)] [Space]
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0, 1)) = 0.9
        
        [Header(Roughness)] [Space]
        [NoScaleOffset] _RoughnessTex ("Roughness Map", 2D) = "black" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.0
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _SpecularColor ("Specular", Color) = (1,1,1,1)

        [Header(NormalTriplanar)] [Space]
        [NoScaleOffset] _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpStrength("Bump Strength", Float) = 1
        
        [Header(Light)] [Space]
        _SunIntensity ("Sun Intensity", Float) = 1

        _DepthThreshold ("Depth Threshold", Float) = 1
        [HDR] _IntersectColor ("Intersect Color", Color) = (1,1,1,1)

        // What color the water will sample when the surface below is shallow.
        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)

        // What color the water will sample when the surface below is at its deepest.
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)

        // Maximum distance the surface below the water will affect the color gradient.
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1

        [Header(Foam)][Space]
        // Color to render the foam generated by objects intersecting the surface.
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FoamSpeed ("Foam Lines Speed", Float) = 0.25
        _FoamTex ("Foam Texture", 2D) = "white" {}
        _FoamCutoff ("Foam Cutoff", Range(0,1)) = 1
        _FoamSmoothness ("Foam Smoothness", Range(0, 1)) = 0.45

        // Control the distance that surfaces below the water will contribute
        // to foam being rendered.
        _FoamMaxDistance("Foam Maximum Distance", Float) = 0.4
        _FoamMinDistance("Foam Minimum Distance", Float) = 0.04

        [Header(Underwater)]
        _WaterSurfaceDistortionStrength ("Water distortion strength", Float) = 1
    }
    CGINCLUDE

    #include "RGBShadersShared.cginc"
    #include "RGBLighting.cginc"

    #define SMOOTHSTEP_AA 0.01
    
    // Blends two colors using the same algorithm that our shader is using
        // to blend with the screen. This is usually called "normal blending",
        // and is similar to how software like Photoshop blends two layers.
    float4 alphaBlend(float4 top, float4 bottom)
    {
        float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
        float alpha = top.a + bottom.a * (1 - top.a);

        return float4(color, alpha);
    }

    #pragma region Input
    struct Input
    {
        float2 uv_MainTex;
        float3 worldNormal;
        INTERNAL_DATA
        float3 worldPos;
        float4 screenPos;
        float3 viewDir;
        float3 viewNormal;
        float facing : VFACE;
        float3 nearPlanePos;
    };
    #pragma endregion Input

    sampler2D _MainTex;
    sampler2D _RoughnessTex;
    
    half _Glossiness;
    half _Metallic;
    fixed4 _Color;
    float _Alpha;

    uniform sampler2D _CameraDepthTexture;
    sampler2D _CameraNormalsTexture;

    float _DepthThreshold;
    float4 _IntersectColor;

    float _DepthMaxDistance;
    float4 _DepthGradientShallow;
    float4 _DepthGradientDeep;

    float _FoamMaxDistance;
    float _FoamMinDistance;

    float4 _FoamColor;
    float _FoamSpeed;
    sampler2D _FoamTex;
    float4 _FoamTex_ST;
    float _FoamCutoff;
    float _FoamSmoothness;

    uniform half4 _CameraDepthTexture_TexelSize;

    ENDCG
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
            "Queue" = "Transparent"
        }
        LOD 200

        GrabPass
        {
            "_UnderwaterTex"
        }

        //Blend SrcAlpha OneMinusSrcAlpha // additive blending for a simple "glow" effect
        Cull Off // render backfaces as well
        ZWrite On // don't write into the Z-buffer, this effect shouldn't block objects
        ZTest LEqual

        CGPROGRAM
        #pragma surface surf StandardSpecular fullforwardshadows vertex:vert 
        #pragma target 4.5
        #pragma shader_feature GESTNER
        
        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.viewNormal = COMPUTE_VIEW_NORMAL;

            float4 vertexProgjPos = mul(UNITY_MATRIX_MV, v.vertex);
            o.nearPlanePos = v.vertex;
        }

        float3 _DeepColor, _ShallowColor;
        float _FogScale, _SSSOpacity, _FogDensity;

        float ShlickFresnel(float3 viewDir, float3 normal)
        {
            const float R = 0.02;
            return R + (1 - R) * Pow5(1 - saturate(abs(dot(viewDir, normal))));
        }

        float _DistanceRange;
        float4 _CloseColor;
        float4 _FarColor;

        float _Perturbation;
        float _SunIntensity;

        void surf (Input i, inout SurfaceOutputStandardSpecular o)
        {
            /////////////////////////////////////////////
            // Standard + Alpha
            o.Albedo = _Color;
            o.Specular = _SpecularColor * _Alpha;
            o.Alpha = _Alpha;

            ////////////////////////////////////////////
            /// Roughness
            float rough = tex2D(_RoughnessTex, i.uv_MainTex);
            o.Smoothness = (1 - rough) * _Glossiness;

            #pragma region Normals
            /////////////////////////////////////////
            // Normal Calculations
            
            #pragma endregion Normals

            // Normals
            o.Normal = UnpackScaleNormal(tex2D(_BumpTex, i.uv_MainTex), _BumpStrength);

            ////////////////////////////////////////////////////////////
            // Depth rendering and Foam
            // Retrieve the current depth value of the surface behind the
            // pixel we are currently rendering.
            // raw depth
            float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
            // Convert the depth from non-linear 0...1 range to linear
            // depth, in Unity units.
            float existingDepthLinear = LinearEyeDepth(existingDepth01);

            // Difference, in Unity units, between the water's surface and the object behind it.
            float depthDifference = existingDepthLinear - i.screenPos.w;
            
            // Calculate the color of the water based on the depth using our two gradient colors.
            float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
            float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);
            o.Albedo = waterColor;
            
            // Retrieve the view-space normal of the surface behind the
            // pixel we are currently rendering.
            float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPos));

            float3 normalDot = saturate(dot(existingNormal, i.viewNormal));
            float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, normalDot);
            float foamDepthDifference01 = saturate(depthDifference / foamDistance);
            
            float foamDiff = foamDepthDifference01;

            float foam = foamDiff - saturate(sin((foamDiff - _Time.y * _FoamSpeed) * 8 * UNITY_PI)) * (1 - foamDiff);
            foam = 1 - foam;
            float foamSample = tex2D(_FoamTex, i.uv_MainTex * _FoamTex_ST.xy + _FoamTex_ST.zw);
            foam = smoothstep(foamSample, foamSample + _FoamSmoothness, foam * _FoamCutoff);
            
            float4 foamColor = foam * _FoamColor * _FoamColor.a;
            o.Emission += foamColor;
            o.Normal = lerp(o.Normal, float3(0, 0, 1), foam * 0.7f);
            
            // Fresnel light
            float fresnel = ShlickFresnel(i.viewDir, o.Normal);
            //o.Albedo += fresnel * _LightColor0.xyz * _SunIntensity;
            o.Emission += fresnel * _LightColor0.xyz * _SunIntensity;
        }

        ENDCG
    }
    FallBack "Transparent/VertexLit"
}
