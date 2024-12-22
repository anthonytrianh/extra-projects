Shader "Anthony/Foliage Wind Translucent"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Specular ("Specular", Range(0, 1)) = 0.07815
        _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
    	_Cutoff ("Cutoff", Range(0, 1)) = 0.1
    	[Toggle(GREYSCALE_ALPHA)] _GreyscaleCutoff ("Greyscale as Alpha", Float) = 0
        
    	[Header(Emission)][Space]
        [Toggle(EMISSIVE)] _Emission ("Emission?", Float) = 0
        _EmissiveTex("Emission Texture", 2D) = "black" {}
        [HDR] _EmissiveColor("Emissive Color", Color) = (0, 0, 0, 0)
    	
        [Header(Normals)][Space]
        _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpStrength("Bump Strength", Float) = 1
        
        [Space]
        [Header(Wind)][Space]
        _WindScale ("Wind Scale", Vector) = (1, 1, 0, 0)
        _WindMovement ("Wind Movement", Vector) = (2, 1, 0, 0)
        _WindDensity ("Wind Density", Float) = 1
        _WindStrength ("Wind Strength", Float) = 0.5
        
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
		[HDR] _SSSubColor ("Subsurface Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    
    CGINCLUDE

    #include "AnthonyPBR.cginc"
    #include "Translucent.cginc"
    #include "Wind.cginc"

    float _Cutoff;

    void vert_foliage(inout appdata_full v, out Input o) 
    {
        UNITY_INITIALIZE_OUTPUT(Input, o);
        o.objPos = ComputeObjectPosition_Vertex(v.vertex);

        // Offset vertex by wind
        float wind = WindSway(v.vertex, v.texcoord);
        v.vertex.x += wind;
    }
    
    ENDCG
    
    SubShader
    {
        Tags { 
        	"RenderType"="Transparent" 
        	"Queue" = "AlphaTest+49"
        }
        LOD 200

        CGPROGRAM
        
        #pragma surface surf_foliage Translucent fullforwardshadows vertex:vert_foliage addshadow
        #pragma target 4.0

        #pragma shader_feature GREYSCALE_ALPHA
		#pragma shader_feature EMISSIVE
        
        void surf_foliage(Input i, inout SurfaceOutput o)
        {
            float2 uv = CalculateUv(i);
            float parallax = GetParallaxOffset(uv, _Height, i.viewDir);
            #ifdef PARALLAX
            uv += parallax;
            #endif

            float4 color = CalculateAlbedo(uv);
            o.Albedo = color;
            o.Gloss = CalculateSmoothness(uv);
            o.Specular = _Specular;
            o.Normal = CalculateNormals(uv);
            o.Emission = CalculateEmissiveColor(uv);
            o.Alpha = color.a;

    		#ifdef GREYSCALE_ALPHA
			clip(tex2D(_MainTex, uv).r - _Cutoff);
			#endif
    	
    	
            //o.Albedo = i.debug;
        }
        
        ENDCG
    }
    FallBack "Bumped Diffuse"
}
