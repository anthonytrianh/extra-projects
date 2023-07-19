Shader "Anthony/Effects/Black Hole"
{
    Properties
    {
        [Header(Rim)]
        [HDR] _Color ("Color", Color) = (1,1,1,1)
        _RimStrength ("Rim Strength", Float) = 1

        [Header(Distortion)][Space]
        _DistortionStrength ("Distortion Power", Float) = 1

        [Header(Hole)][Space]
        _HoleSize("Hole Size", Range(0, 1)) = 0.7030833
        _HoleEdgeSmoothness("Hole Edge Smoothness", Range(0.001, 0.05)) = 0.007289694
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent"
                "IgnoreProjector" = "True"
                "Queue" = "Transparent" }
        LOD 100

        GrabPass
        {
            "_SceneTex"
        }

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
                float3 worldPos : TEXCOORD1;
                //float3 viewDir: TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            uniform sampler2D _SceneTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);;
                //o.viewDir = _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz;
                o.screenPos = ComputeScreenPos(o.vertex);
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

            float _DistortionStrength;
            float4 _Color;
            float _RimStrength;

            float _HoleSize;
            float _HoleEdgeSmoothness;

            fixed4 frag(v2f i) : SV_Target
            {
                // Deform normals
                float3 N = i.normal;

                // Fresnel
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float fres = fresnel(V, i.normal, _DistortionStrength);
                float fresDistort = 1 - fres;
                fresDistort = pow(fresDistort, 6.0);

                // Hole
                float hole = _HoleSize * -1 + 1.0;
                float holeMask = smoothstep(hole + _HoleEdgeSmoothness, hole - _HoleEdgeSmoothness, fresDistort);

                // Rim
                float rim = fresnel(V, N, _RimStrength);
                float4 rimColor = _Color * rim;

                // Scene color
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float4 sceneColor = tex2D(_SceneTex, screenUV + (screenUV * 2 - 1) * fresDistort);

                return sceneColor * holeMask;

                float4 finalColor = lerp(sceneColor, rimColor, 0.5) * holeMask;

                return finalColor;

                //// Random dilation
                //float noise = rand2(_Time.y * 2.0f);
                //float dilation = lerp(0.95, 1.0, noise);

                //fixed4 col = _Color * rim;
                //col = max(col, 1);

                //return col;
            }
            ENDCG
        }
    }
}
