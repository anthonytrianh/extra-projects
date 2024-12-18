Shader "Unlit/LanternGlassGlow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Color ("Color", Color) = (1,1,1,1)
        _Power ("Power", Float) = 2
        
        _GlowParams ("Glow Intensity (XY) Speed (Z)", Vector) = (0.25, 1, 1, 0)
        
        [HDR] _ColorA ("Color A", Color) = (1,0,0,1)
        [HDR] _ColorB ("Color B", Color) = (0,0,1,1)
        
    }
    
    CGINCLUDE
    
    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float4 _MainTex_ST;
    fixed4 _Color;
    fixed _Power;
    fixed4 _GlowParams;

    fixed4 _ColorA;
    fixed4 _ColorB;

    float remap(float v, float minOld, float maxOld, float minNew, float maxNew)
    {
        return minNew + (v - minOld) * (maxNew - minNew) / (maxOld - minOld);
    }
    
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Samples the color from texture
                fixed4 col = tex2D(_MainTex, i.uv);

                // Greyscale
                fixed grey = col.r;
                grey = pow(grey, _Power);

                // _Time.y: 1x time multiplier
                fixed intensityMultiplier = cos(_Time.y * _GlowParams.z);
                // convert from (-1, 1) to (0, 1)
                    //intensityMultiplier = intensityMultiplier * 0.5 + 0.5;
                // remap intensity
                intensityMultiplier = remap(intensityMultiplier, -1, 1, _GlowParams.x, _GlowParams.y);
                grey *= intensityMultiplier;
                
                // Apply color to sampled texture
                //col = grey * _Color;

                // Gradient
                col = lerp(_ColorA, _ColorB, saturate(col.r)) * grey;
                
                return col;
            }
            ENDCG
        }
    }
}
