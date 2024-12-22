Shader "Anthony/Foliage Wind Translucent Rain"
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
    	
    	[Header(Rain)] [Space]
        _Rain ("Rain", Range(0, 1)) = 1
        _RainSmoothnessPower ("Rain Smoothness Power", Float) = 0.1
        
        [Header(Wetness)][Space]
        _WetnessSaturation ("Wet Saturation", Float) = 1
        _WetnessColorDarken ("Wet Color Darken", Float) = 0.5
        _Wetness ("Wetness", Range(0, 1)) = 0.5
        // How water absorbent is the surface?
        _Porousness ("Porousness", Range(0, 1)) = 0.2
        
         [Header(Raindrops)][Space]
         _RainDropsTex ("Rain Drops Texture", 2D) = "bump" {}
         _RainDropsScale ("Rain Drops Scale", Float) = 1
         _RainDropsNormalStrength ("Rain Normal Strength", Float) = 3
         _RainDropsAnimSpeed ("Rain Drops Animation Speed", Float) = 0.7
         _RainDropsAmount ("Rain Drops Amount", Float) = 10
         _RainDropsSmoothnessPower ("Rain Drops Smoothness Power", Float) = 0.1
        
        [Header(Raindrips)][Space]
        _RainDripsTex ("Rain Drips Texture", 2D) = "bump" {}
        _RainDripsWorldScale ("Rain Drips World Scale", Float) = 1
        _RainDripMask ("Rain Drip Mask", 2D) = "black" {}
        _RainDripMaskScale ("Rain Drip Mask Scale", Vector) = (1, 1.05, 1, 0)
        _RainDripsSpeedFast ("Rain Drip Speed Min Max", Vector) = (0.25, 0.7, 0, 0)
        _RainDripsSpeedSlow ("Rain Drip Speed Min Max", Vector) = (0.03, 0.125, 0, 0)
        _RainDripsStrength ("Rain Drips Strength", Float) = 4
        _RainDripsSmoothnessContrast ("Rain Drips Smoothness Contrast", Float) = 1.2
    }
    
    CGINCLUDE

    #include "AnthonyPBR.cginc"
    #include "Translucent.cginc"
    #include "Wind.cginc"
    #include "Rain.cginc"

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

			// Rain
    		WEATHER_RAIN_Gloss(i, o);
    	
        }
        
        ENDCG
    }
    FallBack "Bumped Diffuse"
}
