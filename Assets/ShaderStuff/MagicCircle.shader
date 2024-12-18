Shader "Custom/MagicCircle"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        _Cutoff ("Cutoff", Range(0, 1)) = 0.1
        
        [HDR] _ColorA ("Emissive Color", Color) = (0, 0, 0, 1)
        [HDR] _ColorB ("Emissive Color", Color) = (0, 1, 0, 1)
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseCutoff ("Noise Cutoff", Range(0,1)) = 0
        _NoiseSmoothness ("Noise Smoothness", Range(0, 0.2)) = 0.05
    }
    
    CGINCLUDE

    #include "UnityCG.cginc"
    
    sampler2D _MainTex;
    half _Glossiness;
    half _Metallic;
    fixed4 _Color;
    fixed _Cutoff;
    fixed4 _ColorA, _ColorB;

    sampler2D _NoiseTex;
    fixed4 _NoiseTex_ST; //tiling offset
    fixed _NoiseCutoff;
    fixed _NoiseSmoothness;

    struct Input
    {
        float2 uv_MainTex;
    };
    
    ENDCG
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "TransparentCutout" 
            "Queue" = "AlphaTest"
        }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0
        
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            // Albedo: base color, affected by lighting
            o.Albedo = c.rgb;
            o.Alpha = 1;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        
            clip(c.a - _Cutoff);

        #pragma region Dissolve
            // Calculate noise uvs
            float2 noiseUV = IN.uv_MainTex * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
            // Sample noise
            float noise = tex2D(_NoiseTex, noiseUV);

            // Step(a, x): basically an if statement
            //      if (a < x) returns 0
            //      else returns 1
            float t = step(noise, _NoiseCutoff);

            // smoothstep(a, b, x): instead of comparing a and x
            //      compares x between two values a, b and returns a smoother result
            t = smoothstep(noise - _NoiseSmoothness, noise + _NoiseSmoothness, _NoiseCutoff);
            // Edge case handling for smoothstep
            if (_NoiseCutoff == 0) {
                t = 0;
            }
            else if (_NoiseCutoff == 1) {
                t = 1;
            }
        
            // Emission: colors, unaffected by lighting
            o.Emission = lerp(_ColorA, _ColorB, t);
        #pragma endregion

        
        }
        ENDCG
    }
    FallBack "Diffuse"
}
