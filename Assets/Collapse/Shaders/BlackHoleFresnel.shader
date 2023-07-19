Shader "Anthony/Effects/Black Hole Fresnel Unlit"
{
    Properties
    {
        [HDR] _Color ("Color", Color) = (1,1,1,1)
        _FresnelPower ("Fresnel Power", Float) = 1
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 viewDir: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            // Fresnel
            float fresnel(float3 viewDir, float3 normal, float exp)
            {
                float3 V = viewDir;
                float3 N = normal;

                return pow(1 - saturate(dot(V, N)), exp);
            }


            float rand2(in float2 st)
            {
                return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
            }

            float _FresnelPower;
            float4 _Color;

            fixed4 frag(v2f i) : SV_Target
            {
                // Random dilation
                float noise = rand2(_Time.y * 2.0f);
                float dilation = lerp(0.95, 1.0, noise);
                float rim = fresnel(i.viewDir, i.normal, _FresnelPower * dilation);

                fixed4 col = _Color * rim;

                return col;
            }
            ENDCG
        }
    }
}
