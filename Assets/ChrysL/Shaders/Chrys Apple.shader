Shader "Anthony/Study/Chrys Apple"
{
    Properties
    {
        _RefractionIndex ("Refraction Index", Range(-1, 4)) = 0
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        [Header(Fresnel)][Space]
        _Fresnel ("Fresnel", Range(0, 1)) = 1
        _FresnelPower ("Fresnel Power", Float) = 1
        [HDR] _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        [HDR] _FresnelColorB ("Fresnel Color B", Color) = (1,1,1,1)
        
        [Header(Noise)][Space]
        _NoiseTex ("Noise Tex", 2D) = "black" {}
        _NoiseStrength ("Noise Strength", Float) = 0.1
    }
    SubShader
    {
        Tags 
        { 
            "Queue" = "Transparent"
        }

        GrabPass
        {
            "_BackgroundTexture"
        }

        Blend SrcAlpha OneMinusSrcAlpha

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard noshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0


        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float4 screenPos;
        };

        sampler2D _BackgroundTexture;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        float _RefractionIndex;

        float _Fresnel, _FresnelPower;
        float4 _FresnelColor, _FresnelColorB;

        sampler2D _NoiseTex;
        float4 _NoiseTex_ST;
        float _NoiseStrength;

        // Fresnel
        float fresnel(float3 viewDir, float3 normal, float exp)
        {
            float3 V = viewDir;
            float3 N = normal;

            return pow(1 - saturate(dot(V, N)), exp);
        }

        float3 GetFresnelColor(float3 viewDir, float3 normal)
        {
            float f = fresnel(viewDir, normal, _FresnelPower);
            return lerp(_FresnelColor, _FresnelColorB, f);
        }

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c =  _Color;
            o.Albedo = c.rgb;

            // Noise
            float noise = tex2D(_NoiseTex, i.uv_MainTex * _NoiseTex_ST.xy) * _NoiseStrength;
          
            // Refraction
            float refractIndex = _RefractionIndex;
            float3 refractDir = refract(normalize(o.Normal + float3(noise.xx, 0)), i.viewDir, refractIndex);

            float4 screenPos = i.screenPos;
            screenPos.xyz += refractDir;

            // Sample background texture
            float2 screenUV = screenPos.xy / screenPos.w;
            float3 background = tex2D(_BackgroundTexture, screenUV);

            // Fresnel
            float3 fresnelColor = GetFresnelColor(i.viewDir, normalize(o.Normal + float3(noise.xx, 0)));
            
            o.Emission = lerp(background, fresnelColor, _Fresnel);

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
