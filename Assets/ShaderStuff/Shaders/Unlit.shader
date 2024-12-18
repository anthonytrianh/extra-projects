Shader "Unlit/Unlit"
{
    // Properties, params (specified in materials)
    Properties
    {
        // _Paramater ("ParameterNameInInspector", Type) = <Default value>
        _Float ("Float", Float) = 0
        _Int ("Int", Int) = 1
        _Range ("Range", Range(0, 1)) = 0
        _Vector ("Vector", Vector) = (0,0,0,0) // Vector4
        _Color ("Color", Color) = (1, 0, 0, 0)
        
        _ColorTop ("Color Top", Color) = (1,0,0,1)
        _ColorBot ("Color Bottom", Color) = (1, 0, 1, 1)
        
        // _Tex.. ("TextureName", 2D) = <white, black, grey, bump> {}
        // Note: "bump" is used for default normals
        _Tex2D ("Texture 2D", 2D) = "black" {}
        // Controls the texture panning speed and direction
        _Panning ("Panning Speed (XY)", Vector) = (1, 1, 0, 0)
        // Determines threshold for cutout transparency
        _CutoffThreshold ("Cutoff Threshold", Range(0, 1)) = 0.01
    }
    
    CGINCLUDE
        // Parameters
        sampler2D _Tex2D;
        float4 _Tex2D_ST;
        float4 _Panning;
        float _CutoffThreshold;

        float4 _ColorTop;
        float4 _ColorBot;
    ENDCG
    
    SubShader
    {
        Tags 
        { 
            // Render type: Opaque, TransparentCutout, Transparent
            "RenderType"="TransparentCutout"
            // Queue: determines the order in which things are rendered
            "Queue" = "Geometry+450"
        }
        LOD 100
        
        // Commands

        // ....
        
        Pass
        {
            CGPROGRAM // --- BEGINNING of shader program ---- //
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // Data read from the mesh
            struct meshInput
            {
                float4 vertex : POSITION; // POSITION: vertex data
                float2 uv : TEXCOORD0;  // TEXCOORD0: first UV set
                float3 normal : NORMAL; // NORMAL: mesh normal
                float4 color : COLOR; // COLOR: **vertex** color
            };

            // Interpolators
            struct v2f // vertex to fragment
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            v2f vert (meshInput v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv; //TRANSFORM_TEX(v.uv, _Tex2D);
                return o;
            }
            
            // DO COLOR STUFF, returns final color
            fixed4 frag (v2f i) : SV_Target
            {
                // rgba, xyzw
                fixed4 col = float4(i.uv, 0, 1);
                col.r = i.uv.x;
                col.g = i.uv.y;
                col.b = 1;

                // float2 uv2 = i.uv * 2 - 1;
                // float len = length(uv2);
                // return len;  

                float t =  i.uv.y + _Time.y;
                t = frac(abs(t));
                t = abs(t * 2 - 1); // remaps (0, 1) -> (-1, 1)
                
                fixed4 gradient = lerp(_ColorBot, _ColorTop, t);
                
                // Texture mapping
                float2 uv = i.uv  * _Tex2D_ST.xy + _Tex2D_ST.zw;
                // Panning, _Time.y
                uv += _Time.y * _Panning.xy;
                // tex2D(sampler2D, float2): samples a texture2D based on float2 uv, returns float4 color
                float4 texColor = tex2D(_Tex2D, uv);
                float alpha = texColor.a;
                // Discard pixels, clip(x): discards all pixels with lower values than what we give it
                clip(alpha - _CutoffThreshold);
                
                return texColor + gradient;
            }
            ENDCG
        }
        
    }
}
