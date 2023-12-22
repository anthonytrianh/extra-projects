Shader "Unlit/SignHologram"
{
	Properties
	{
		[Header(Texture)][Space]
		// Main Color
		_MainTex ("MainTexture", 2D) = "white" {}
		[HDR] _MainColor ("MainColor", Color) = (1,1,1,1)
		
		[Header(Fade)][Space]
		// Fade
		_FadeTex ("Fade Texture", 2D) = "white" {}
		[HDR] _FadeColor ("Fade Color", Color) = (1,1,1,1)
		_FadeSpeed ("Fade Speed", Float) = 0.5
		
		// General
		_Alpha ("Alpha", Range (0.0, 1.0)) = 1.0
		_Direction ("Direction", Vector) = (0,1,0,0)
		// Rim/Fresnel
		_RimColor ("Rim Color", Color) = (1,1,1,1)
		_RimPower ("Rim Power", Range(0.1, 10)) = 5.0
		// Scanline
		_ScanTiling ("Scan Tiling", Range(0.01, 10.0)) = 0.05
		_ScanSpeed ("Scan Speed", Range(-2.0, 2.0)) = 1.0
		_ScanOpacity ("Scan Opacity", Range(0,1)) = 0.5
		
		// Glitch
		_GlitchSpeed ("Glitch Speed", Range(0, 50)) = 1.0
		_GlitchIntensity ("Glitch Intensity", Float) = 0
		// Flicker
		 [Header(Flicker)] [Space]
        _Flicker ("Min Max Flicker (XY), Speed (Z)", Vector) = (0.95, 1.05, 1, 0)

		// Settings
		[HideInInspector] _Fold("__fld", Float) = 1.0
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "RenderType"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		LOD 100
		ColorMask RGB
        Cull Off

		Pass
		{
			CGPROGRAM
			#pragma shader_feature _SCAN_ON
			#pragma shader_feature _GLOW_ON
			#pragma shader_feature _GLITCH_ON
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "ShaderMaths.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 worldVertex : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				float3 worldNormal : NORMAL;
			};

			sampler2D _MainTex;
			sampler2D _FlickerTex;
			float4 _Direction;
			float4 _MainTex_ST;
			float4 _MainColor;
			float4 _RimColor;
			float _RimPower;
			float _GlitchSpeed;
			float _GlitchIntensity;
			float _Brightness;
			float _Alpha;
			float _ScanTiling;
			float _ScanSpeed;
			float _ScanOpacity;
			float _GlowTiling;
			float _GlowSpeed;
			float _FlickerSpeed;
			float4 _Flicker;
			sampler2D _FadeTex;
			float4 _FadeTex_ST;
			float4 _FadeColor;
			float _FadeSpeed;
			
			v2f vert (appdata v)
			{
				v2f o;
				
				// Glitches
				#if _GLITCH_ON
					v.vertex.x += _GlitchIntensity * (step(0.5, sin(_Time.y * 2.0 + v.vertex.y * 1.0)) * step(0.99, sin(_Time.y*_GlitchSpeed * 0.5)));
				#endif

				o.vertex = UnityObjectToClipPos(v.vertex);
				
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldVertex = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.viewDir = normalize(UnityWorldSpaceViewDir(o.worldVertex.xyz));

				return o;
			}

			
			fixed4 frag (v2f i) : SV_Target
			{
				// Main color
				fixed4 texColor = tex2D(_MainTex, i.uv);

				// Fade
				float mainMask = texColor.a;
				float4 fadeSample = tex2D(_FadeTex, i.uv * _FadeTex_ST.xy + float2(_FadeSpeed, 0) * _Time.y);

				// Scanlines
				half dirVertex = (dot(i.worldVertex, normalize(float4(_Direction.xyz, 1.0))) + 1) / 2 * 50.0f;
				float scan = 0.0;
				scan = step(frac(dirVertex * _ScanTiling  + _Time.w * _ScanSpeed), 0.5) * 0.65;
				scan = lerp(_Alpha, scan, _ScanOpacity);

				// Flicker
				fixed4 flicker = lerp(_Flicker.x, _Flicker.y, rand2(_Time.x * _Flicker.z));

				// Rim Light
				half rim = 1.0-saturate(dot(i.viewDir, i.worldNormal));
				fixed4 rimColor = _RimColor * pow (rim, _RimPower);

				fixed4 col = texColor;
				col = lerp(col, fadeSample, mainMask);
				col *= _MainColor;
				
				col += rimColor;
				col.a = lerp(texColor.a, fadeSample.a, mainMask);
				col.a *= _Alpha * (scan + rim);
				col *= flicker;
				
				return col;
			}
			ENDCG
		}
	}

}
