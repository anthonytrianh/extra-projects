Shader "Anthony/Study/Glass"
{
    Properties
    {
        _RefractionIndex ("Refraction Index", Range(-1, 1)) = 0
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
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

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c =  _Color;
            o.Albedo = c.rgb;

            // Refraction
            float refractIndex = _RefractionIndex;
            float3 refractDir = refract(normalize(o.Normal), i.viewDir, refractIndex);

            float4 screenPos = i.screenPos;
            screenPos.xyz += refractDir;

            // Sample background texture
            float2 screenUV = screenPos.xy / screenPos.w;
            float3 background = tex2D(_BackgroundTexture, screenUV);

            o.Emission = background;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
