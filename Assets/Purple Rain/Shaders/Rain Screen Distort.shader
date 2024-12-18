Shader "Unlit/Rain Screen Distort"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DistortStrength ("Distortion Strength", Float) = .1
    }
    
    CGINCLUDE

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float4 color : COLOR;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uv : TEXCOORD0;
            float4 color : TEXCOORD1;
            float4 screenPos : TEXCOORD2;
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;
        float _DistortStrength;
        uniform sampler2D _BackgroundTex;

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            o.color = v.color;
            o.screenPos = ComputeScreenPos(o.vertex);
            return o;
        }

    ENDCG
    
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue" = "Transparent"
        }
        LOD 100

        GrabPass
        {
            "_BackgroundTex"
        }
        
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 particleColor = i.color;
                fixed4 col = tex2D(_MainTex, i.uv);

                // Screen distort
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                // Distort screen uvs
                screenUV += col.r * _DistortStrength;

                col = tex2D(_BackgroundTex, screenUV) * particleColor;
                
                return col;
            }
           
            ENDCG
        }
    }
}
