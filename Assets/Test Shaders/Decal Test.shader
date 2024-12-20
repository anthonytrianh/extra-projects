Shader "Anthony/Decal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    
    CGINCLUDE

     #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex   : POSITION;
            float4 normal   : NORMAL;
            float2 uv       : TEXCOORD0;
            fixed4 color    : COLOR0;

        	UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        // Forward rendering decals
        struct v2f_decal
        {
            float4 vertex		: SV_POSITION;
            float4 normal		: NORMAL;
            
            float2 uv           : TEXCOORD0;
            float4x4 mpv_inv    : TEXCOORD1;
            float4 screenPos    : TEXCOORD5;
            float3 ray          : TEXCOORD6;

	        UNITY_FOG_COORDS(7)
            
            fixed4 color        : COLOR;
        };

	    inline float4x4 inverseMat(float4x4 mat)
		{
			float s0 = mat[0][0] * mat[1][1] - mat[1][0] * mat[0][1];
			float s1 = mat[0][0] * mat[1][2] - mat[1][0] * mat[0][2];
			float s2 = mat[0][0] * mat[1][3] - mat[1][0] * mat[0][3];
			float s3 = mat[0][1] * mat[1][2] - mat[1][1] * mat[0][2];
			float s4 = mat[0][1] * mat[1][3] - mat[1][1] * mat[0][3];
			float s5 = mat[0][2] * mat[1][3] - mat[1][2] * mat[0][3];

			float c5 = mat[2][2] * mat[3][3] - mat[3][2] * mat[2][3];
			float c4 = mat[2][1] * mat[3][3] - mat[3][1] * mat[2][3];
			float c3 = mat[2][1] * mat[3][2] - mat[3][1] * mat[2][2];
			float c2 = mat[2][0] * mat[3][3] - mat[3][0] * mat[2][3];
			float c1 = mat[2][0] * mat[3][2] - mat[3][0] * mat[2][2];
			float c0 = mat[2][0] * mat[3][1] - mat[3][0] * mat[2][1];

			float d = (s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0);

			d = d <= 0.0f ? 1.0f : d;

			float invdet = 1.0f / d;

			float4x4 b;

			b[0][0] = ( mat[1][1] * c5 - mat[1][2] * c4 + mat[1][3] * c3) * invdet;
			b[0][1] = (-mat[0][1] * c5 + mat[0][2] * c4 - mat[0][3] * c3) * invdet;
			b[0][2] = ( mat[3][1] * s5 - mat[3][2] * s4 + mat[3][3] * s3) * invdet;
			b[0][3] = (-mat[2][1] * s5 + mat[2][2] * s4 - mat[2][3] * s3) * invdet;

			b[1][0] = (-mat[1][0] * c5 + mat[1][2] * c2 - mat[1][3] * c1) * invdet;
			b[1][1] = ( mat[0][0] * c5 - mat[0][2] * c2 + mat[0][3] * c1) * invdet;
			b[1][2] = (-mat[3][0] * s5 + mat[3][2] * s2 - mat[3][3] * s1) * invdet;
			b[1][3] = ( mat[2][0] * s5 - mat[2][2] * s2 + mat[2][3] * s1) * invdet;

			b[2][0] = ( mat[1][0] * c4 - mat[1][1] * c2 + mat[1][3] * c0) * invdet;
			b[2][1] = (-mat[0][0] * c4 + mat[0][1] * c2 - mat[0][3] * c0) * invdet;
			b[2][2] = ( mat[3][0] * s4 - mat[3][1] * s2 + mat[3][3] * s0) * invdet;
			b[2][3] = (-mat[2][0] * s4 + mat[2][1] * s2 - mat[2][3] * s0) * invdet;

			b[3][0] = (-mat[1][0] * c3 + mat[1][1] * c1 - mat[1][2] * c0) * invdet;
			b[3][1] = ( mat[0][0] * c3 - mat[0][1] * c1 + mat[0][2] * c0) * invdet;
			b[3][2] = (-mat[3][0] * s3 + mat[3][1] * s1 - mat[3][2] * s0) * invdet;
			b[3][3] = ( mat[2][0] * s3 - mat[2][1] * s1 + mat[2][2] * s0) * invdet;

			return b;
		}

		uniform sampler2D _CameraDepthTexture;
    
        v2f_decal vert (appdata v)
        {
            v2f_decal o;

            // Decal initialize
			fixed ortho = unity_OrthoParams.w;
			float4 pp = float4(v.vertex.xyz, 1.0f);
			float4 p = UnityObjectToClipPos (pp);
			float4x4 mi = ortho ? inverseMat(UNITY_MATRIX_MVP) : mul(unity_WorldToObject, unity_CameraToWorld);
			float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
			o.vertex = p;
			o.normal = v.normal;
			o.screenPos = ComputeScreenPos(p);
			o.ray = mul(UNITY_MATRIX_MV, pp).xyz * float3(-1, -1, 1);
			o.uv = v.uv;
			o.color = v.color;
			o.mpv_inv = mi;
            
            // Transfer fog
            UNITY_TRANSFER_FOG(o,o.vertex);
            return o;
        }
		void ProcessDecal(inout v2f_decal i, out float2 decalUV)
        {
	        fixed ortho = unity_OrthoParams.w;
			float4x4 invMVP = i.mpv_inv;
			i.ray = ortho ? i.ray : i.ray * (_ProjectionParams.z / i.ray.z);
			float2 screenUV = i.screenPos.xy / i.screenPos.w;
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
			depth = ortho ? depth : Linear01Depth(depth);
			float4 viewPos = ortho ? float4(i.ray.xy, depth, 1.0f) : float4(i.ray * depth, 1.0f);
			float4 worldPos = mul (invMVP, viewPos);
			float3 localPos = worldPos.xyz / worldPos.w;
			clip(0.5f - abs(localPos));
        	localPos += 0.5f;
        	decalUV = localPos.xz;
        }
    
		sampler2D _MainTex;
        float4 _MainTex_ST;
    
    ENDCG
    
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue" = "Transparent+1" 
            "DisableBatching" = "True" 
        }
        LOD 100

        Stencil
		{
			Ref 1
			Comp notequal
			Pass keep
		}
        
		Blend SrcAlpha OneMinusSrcAlpha
        ZWrite On 
		ZTest Always
		Lighting Off
		Cull Front
		Offset -1,-1
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            fixed4 frag (v2f_decal i) : SV_Target
            {
            	float2 uv;
				ProcessDecal(i, uv);
				fixed4 color =  tex2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw * -1.f);
            	
                // sample the texture
                fixed4 col = color;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
