Shader "Anthony/Foliage Wind PBR"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        [Space]
        [Header(Wind)][Space]
        _WindScale ("Wind Scale", Vector) = (1, 1, 0, 0)
        _WindMovement ("Wind Movement", Vector) = (2, 1, 0, 0)
        _WindDensity ("Wind Density", Float) = 1
        _WindStrength ("Wind Strength", Float) = 0.5
    }
    
    CGINCLUDE

    #include "AnthonyPBR.cginc"
    #include "Wind.cginc"
    
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        
        #pragma surface surf_pbr_foliage Standard fullforwardshadows vertex:vert_foliage
        #pragma target 4.0

        void vert_foliage(inout appdata_full v, out Input o) 
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.objPos = ComputeObjectPosition_Vertex(v.vertex);

            // Offset vertex by wind
            float wind = WindSway(v.vertex, v.texcoord);
            v.vertex.x += wind;
        }
        
        void surf_pbr_foliage(Input i, inout SurfaceOutputStandard o)
        {
            float2 uv = CalculateUv(i);
            float parallax = GetParallaxOffset(uv, _Height, i.viewDir);
            #ifdef PARALLAX
            uv += parallax;
            #endif

            float4 color = CalculateAlbedo(uv);
            o.Albedo = color;
            o.Metallic = CalculateMetallic(uv);
            o.Smoothness = CalculateSmoothness(uv);
            o.Normal = CalculateNormals(uv);
            o.Emission = CalculateEmissiveColor(uv);
            o.Alpha = color.a;

            //o.Albedo = i.debug;
        }

        
        ENDCG
    }
    FallBack "Diffuse"
}
