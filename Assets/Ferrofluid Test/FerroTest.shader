Shader "Custom/FerroTest"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        [Header(Ferro)][Space]
        _SpikeLength ("Spike Length", Float) = 0.2
        _NoiseTex ("Noise Texture", 2D) = "black" {}
        
        
        _DebugMagnet ("Debug Magnet Position", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        #pragma target 4.0

        sampler2D _MainTex;

        uniform float3 _MagnetPosition;

        struct appdata
        {
            float4 vertex : SV_POSITION;
            float2 texcoord : TEXCOORD0;
            float3 normal : NORMAL;
        };
        
        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            float3 worldNormal; INTERNAL_DATA
            float3 viewDir;
            float2 debug;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _MagnetRadius;
        float _SpikeLength;

        void vert(inout appdata v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            float3 sphereVerts = normalize(v.vertex.xyz) * .97;
                
            float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
            float dist = length(worldPos - _MagnetPosition);
            float mask = step(dist, 1);

            v.vertex.xyz = lerp(sphereVerts, v.vertex.xyz, mask);
            o.debug = mask.xx;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = 0;

            c.rgb = IN.debug.xxx;
             
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
