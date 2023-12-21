Shader "Unlit/Bored"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "ShaderMaths.cginc"

            #define TAU 6.28318

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            ///////////////////////
            // Bored shader
            float3 palette(float t) 
            {
                // [[0.508 0.500 1.248] [0.388 -0.912 0.758] [1.000 1.000 0.638] [0.000 0.333 1.038]]
                float3 a = float3(0.508, 0.5, 1.248);
                float3 b = float3(0.33, -0.912, 0.758);
                float3 c = float3(1.0, 1.0, 0.638);
                float3 d = float3(0, 0.33, 1.038);

                return a + b * cos(TAU * (c * t + d));
            }

            float raysSDFUncentered(float2 uv, int n)
            {
                // Centers uv
                return frac(atan2(uv.y, uv.x) / TAU * float(n));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float2 uv0 = uv * 2 - 1;
                float3 finalColor;

                int maxSteps = 4;
                for (int j = 0; j < maxSteps; j++) 
                {
                    uv = frac(uv * 1.6) - 0.5;

                    float dist;
                    float rays = raysSDFUncentered(uv, 3) + _Time.y * 0.3;
                    dist = rays;
                    // Exponential
                    float e = exp(-pow(sin(.5 * uv0 + _Time.y * 0.7), 2) + sin(0.7 * uv0));
                    dist += e * 1.77;

                    float3 col = palette(raysSDFUncentered(uv0, 7) + _Time.y * 0.2 + j * .55);

                    dist = sin(dist * 8. + _Time * 0.5) / 8.;
                    dist = abs(dist);
                    dist = pow(0.0025 / dist, 0.66);
                    col *= dist;

                    finalColor += col * 0.8;
                }

                return float4(finalColor, 1);
            }
            ENDCG
        }
    }
}
