Shader "Custom/AmuletGem"
{
    Properties
    {
        [HDR]  _Color("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Reflectivity ("Reflectivity", Range(0, 1)) = 1

        [Header(Fresnel)]
        _FresnelColor("Rim Color", Color) = (1,1,1,1)
        _FresnelPower("Rim Power", Range(0,10)) = 1
        _FresnelStrength("Rim Strength", Float) = 1
        _FresnelOpacity("Fresnel Opacity", Range(0, 1)) = 1

        [HDR] _TopColor("Top Color", Color) = (1,1,1,1)
        _TopLine ("Top Line", Range(0, 1)) = 0.65
        [HDR] _BottomColor("Bottom Color", Color) = (0,0,0,0)
        _BottomLine("Bottom Line", Range(0, 1)) = 0.35

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.5

        #include "ShaderMaths.cginc"
        #include "RGBLighting.cginc"

        sampler2D _MainTex;
         
        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
            INTERNAL_DATA
            float3 worldPos;
            float3 viewDir;
            float4 screenPos;
            float3 worldRefl;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float4 _TopColor;
        float _TopLine;
        float4 _BottomColor;
        float _BottomLine;

        float _Reflectivity;

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, i.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            float3 L = _WorldSpaceLightPos0.xyz;
            float3 V = i.viewDir;
            float3 N = i.worldNormal;

            // Fresnel
            float fresnel = Fresnel(N, V, true);
            float3 fresnelColor = FresnelColor(N, V, true);

            float gradientV = (1-i.uv_MainTex.y) * 0.97;
            float topFresnel = smoothstep(1 - gradientV, 1, _TopLine) * fresnel;
            float bottomFresnel = smoothstep(gradientV, 1, _BottomLine) * fresnel;

            float3 topColor = topFresnel * _TopColor;
            float3 bottomColor = bottomFresnel * _BottomColor;

            fresnelColor = topColor + bottomColor;
            o.Emission = fresnelColor;

            // Reflections
            half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //Direction of ray from the camera towards the object surface
            half3 reflection = reflect(-worldViewDir, i.worldNormal); // Direction of ray after hitting the surface of object
            /*If Roughness feature is not needed : UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflection) can be used instead.
            It chooses the correct LOD value based on camera distance*/
            half4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, 1 - _Glossiness); //UNITY_SAMPLE_TEXCUBE_LOD('cubemap', 'sample coordinate', 'map-map level')
            half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR) * _Reflectivity;

            o.Emission = max(fresnelColor, skyColor);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
