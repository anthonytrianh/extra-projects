Shader "Anthony/ImageEffects/Glitch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Glitch)][Space]
        _NoiseAmount ("Noise Amount", Float) = 1
        _GlitchSpeed ("Glitch Speed", Float) = 1
        _GlitchOpacity ("Glitch Opacity", Range(0, 1)) = 0.9
    }
    CGINCLUDE
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

    void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
    {
        Out = unity_gradientNoise(UV * Scale) + 0.5;
    }

    float remap(float v, float minOld, float maxOld, float minNew, float maxNew)
    {
        return minNew + (v - minOld) * (maxNew - minNew) / (maxOld - minOld);
    }
    ENDCG
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _NoiseAmount;
            float _GlitchSpeed;
            float _GlitchOpacity;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                ///////////////////////////
                // Glitch lines
                float2 uv = i.uv;
                // Animate uv
                float linesUV = uv.y + _GlitchSpeed * _Time.y;

                // Gradient noise using only vertical uv (v)
                float noise;
                Unity_GradientNoise_float(linesUV, _NoiseAmount, noise);

                // Remap noise for contrast
                float lines = remap(noise, 0, 1, -.8, .8);

                /////////////////////////////
                // Flicker
                float flicker;
                Unity_GradientNoise_float(_GlitchSpeed * _Time.x, 0.5, flicker);
                // Make flicker stronger by multiplying with itself, or pow
                flicker *= flicker;
                flicker *= flicker;
                // Darken the flicker
                flicker *= 0.05;

                // Combine flicker with lines
                float glitch = lines * flicker;

                // Scene
                uv += float2(glitch, 0);

                fixed4 col = tex2D(_MainTex, lerp(i.uv, uv, _GlitchOpacity));
                return col;
            }
            ENDCG
        }
    }
}
