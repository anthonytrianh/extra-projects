Shader "Anthony/Foliage Wind Translucent"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Specular ("Specular", Range(0, 1)) = 0.07815
        _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
        
        [Space]
        [Header(Wind)][Space]
        _WindScale ("Wind Scale", Vector) = (1, 1, 0, 0)
        _WindMovement ("Wind Movement", Vector) = (2, 1, 0, 0)
        _WindDensity ("Wind Density", Float) = 1
        _WindStrength ("Wind Strength", Float) = 0.5
        
        [Space]
        [Header(Translucent)][Space]
        //_Thickness = Thickness texture (invert normals, bake AO).
		//_Power = "Sharpness" of translucent glow.
		//_Distortion = Subsurface distortion, shifts surface normal, effectively a refractive index.
		//_Scale = Multiplier for translucent glow - should be per-light, really.
		//_SubColor = Subsurface colour.
		_SSThickness ("Subsurface Thickness (R)", 2D) = "bump" {}
		_SSPower ("Subsurface Power", Float) = 1.0
		_SSDistortion ("Subsurface Distortion", Float) = 0.0
		_SSScale ("Subsurface Scale", Float) = 0.5
		_SSSubColor ("Subsurface Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    
    CGINCLUDE

    #include "AnthonyPBR.cginc"

    ///////////////////////////
    // Gradient noise
    float2 unity_gradientNoise_dir(float2 p)
    {
        p = p % 289;
        float x = (34 * p.x + 1) * p.x % 289 + p.y;
        x = (34 * x + 1) * x % 289;
        x = frac(x / 41) * 2 - 1;
        return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
    }

    float unity_gradientNoise(float2 p)
    {
        float2 ip = floor(p);
        float2 fp = frac(p);
        float d00 = dot(unity_gradientNoise_dir(ip), fp);
        float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
        float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
        float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
        fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
        return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
    }

    float GradientNoise(float2 UV, float Scale)
    {
        return unity_gradientNoise(UV * Scale) + 0.5;
    }
    /////////////////////////////////////

    float2 _WindScale;
    float2 _WindMovement;
    float _WindDensity;
    float _WindStrength;

    #include "Translucent.cginc"
    
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        
        #pragma surface surf_foliage Translucent fullforwardshadows vertex:vert_foliage
        #pragma target 4.0

        void vert_foliage(inout appdata_full v, out Input o) 
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.objPos = ComputeObjectPosition_Vertex(v.vertex);

            ///////////////////////////
            // Wind
            //!! World Position must be manually calculated here, o.worldPos is not yet calculated at this stage
            float3 worldPosition = mul(unity_ObjectToWorld, v.vertex);
            float2 windUV = worldPosition.xy / _WindScale.xy + _Time.y * _WindMovement.xy;
            float noise = GradientNoise(windUV, _WindDensity);
            float wind = noise - 0.5;
            wind *= _WindStrength;
            wind *= v.texcoord.y;

            // Offset vertex by wind
            v.vertex.x += wind;

            o.debug = noise;
        }
        
        void surf_foliage(Input i, inout SurfaceOutput o)
        {
            float2 uv = CalculateUv(i);
            float parallax = GetParallaxOffset(uv, _Height, i.viewDir);
            #ifdef PARALLAX
            uv += parallax;
            #endif

            float4 color = CalculateAlbedo(uv);
            o.Albedo = color;
            o.Gloss = CalculateSmoothness(uv);
            o.Specular = _Specular;
            o.Normal = CalculateNormals(uv);
            o.Emission = CalculateEmissiveColor(uv);
            o.Alpha = color.a;

            //o.Albedo = i.debug;
        }

        
        ENDCG
    }
    FallBack "Diffuse"
}
