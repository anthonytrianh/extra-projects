Shader "Custom/FBM"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [HDR] _FractalColor ("Fractal Color", Color) = (1,0,0,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [Header(FBM)][Space]
        _Scale ("Scale", Float) = 7
        _ScaleMultiplicationStep ("Scale Multiplication Step", Float) = 1.2
        _Iterations ("Iterations", Float) = 16
        _AnimSpeed ("Animation Speed", Float) = 1
        _RotationStep ("Rotation Step", Float) = 5
        _Frequency ("Frequency", Float) = 4
        _RippleStrength ("Ripple Strength", Float) = 0.8
        _Q ("Q", Float) = 1
        _Normal ("Normal Strength", Float) = 1
    }
    CGINCLUDE

    ENDCG
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        struct Input
        {
            float2 uv_MainTex;
            float3 vertex;
            float3 normal;
            float3 worldPos;
            float3 worldNormal; INTERNAL_DATA
        };

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _FractalColor;

        float _Scale;
        float _ScaleMultiplicationStep;
        float _Iterations;
        float _AnimSpeed;
        float _RotationStep;
        float _Frequency;
        float _RippleStrength;
        float _Normal;
        float _Q;

        //// Calculate normal for raymarched point
        //float3 GetNormal(float3 p)
        //{
        //    float2 e = float2(1e-2, 0);
        //    float3 n = GetDist(p) - float3(
        //        GetDist(p - e.xyy),
        //        GetDist(p - e.yxy),
        //        GetDist(p - e.yyx)
        //        );
        //    return normalize(n);
        //}

        float2x2 RM2D(float a)
        {
            return float2x2(cos(a), sin(a), -sin(a), cos(a));
        }

        float FBM(Input i)
        {
           
            /*o *= 8;
            o = floor(o);
            o /= 8;*/

            return 0;
        }

        float3 NormalFromHeight(float height, float3 worldPos, float3 worldNormal) 
        {
            float3 worldDerivativeX = ddx(worldPos * 100);
            float3 crossX = cross(worldNormal, worldDerivativeX);
            float3 crossY = cross(worldNormal, ddy(worldPos * 100));

            float crossYDotWorldDerivX = abs(dot(crossY, worldDerivativeX));
            float3 a = ddx(height) * crossY;
            float3 b = ddy(height) * crossX;
            float3 c = a + b;
            float3 d = c * sign(crossYDotWorldDerivX);
            d.y *= -1;
            float3 e = crossYDotWorldDerivX * worldNormal - d;
            return normalize(e);
        }

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, i.uv_MainTex) * _Color;

            float2 uv = i.uv_MainTex;

            /*uv *= 32;
            uv = floor(uv);
            uv /= 32;*/

            float2 n, q, u = float2(uv - 0.5);
            float d = dot(u, u), s = _Scale, t = _Time.y * _AnimSpeed, fbm, j;
            float rough;
            float3 color = 0;

            for (float2x2 m = RM2D(_RotationStep); j++ < _Iterations;)
            {
                u = mul(m, u);
                n = mul(m, n);
                q = u * s + t * _Frequency + sin(t * 4 - d * 6) * _RippleStrength + j + n;
                fbm += dot(cos(q) / s, float2(2, 2));
                rough += dot(cos(q * _Q) / s, float2(2, 2));
                n -= sin(q);
                s *= _ScaleMultiplicationStep;
            }
            color += fbm * _FractalColor.rgb;

            o.Albedo = fbm * _Color;
            o.Emission = color;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            float3 tnormal = i.normal;
            float3 worldNormal = WorldNormalVector(i, tnormal);
            o.Emission = NormalFromHeight(fbm * _Normal, i.worldPos, i.worldNormal);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
