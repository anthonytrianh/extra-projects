Shader "Custom/Translucent" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normal (Normal)", 2D) = "bump" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		
		// Specular
		_Specular ("Specular", Range(0, 1)) = 0.07815
        _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)

		[Space]
        [Header(Translucent)][Space]
        //_Thickness = Thickness texture (invert normals, bake AO).
		//_Power = "Sharpness" of translucent glow.
		//_Distortion = Subsurface distortion, shifts surface normal, effectively a refractive index.
		//_Scale = Multiplier for translucent glow - should be per-light, really.
		//_SubColor = Subsurface colour.
		_SSThickness ("Subsurface Thickness (R)", 2D) = "bump" {}
		_SSPower ("Subsurface Power", Float) = 1.0
		_SSDistortion ("Subsurface Distortion", Float) = 0.0
		_SSScale ("Subsurface Scale", Float) = 0.5
		_SSSubColor ("Subsurface Color", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	CGINCLUDE
    #include "Translucent.cginc"

	sampler2D _MainTex, _BumpMap, _Thickness;
    fixed4 _Color;
    half _Specular;

    struct Input
    {
		float2 uv_MainTex;
    };

	void surf (Input IN, inout SurfaceOutput o) {
		fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
		o.Albedo = tex.rgb * _Color.rgb;
		o.Alpha = tex2D(_Thickness, IN.uv_MainTex).r;
		o.Gloss = tex.a;
		o.Specular = _Specular;
		o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
	}
    
	ENDCG
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Translucent
		
		ENDCG
	}
	FallBack "Bumped Diffuse"
}