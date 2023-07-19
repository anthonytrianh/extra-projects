Shader "Custom/Amulet"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [Header(CubeReflection)]
        _Cube("Reflection cube map", Cube) = "" {}
        _ReflAmount("Reflection Amount", Float) = 0.5

        [Header(Detail)]
        _DetailTex ("Detail Texture", 2D) = "white" {}
        _DetailOpacity ("Detail Opacity", Range(0,1)) = 1.0
        _DetailCutoff ("Detail Cutoff", Range(0, 1)) = 0.8
        _DetailFuzziness ("Detail Fuzziness", Range(0, 1)) = 0.05
        _GradientTop ("Gradient Top", Color) = (1,1,1,1)
        _GradientBot ("Gradient Bottom", Color) = (1,1,1,1)

        [Header(NormalMap)]
        _BumpTex ("Bump Texture", 2D) = "bump" {}
        _BumpStrength ("Bump Strength", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.5

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
            INTERNAL_DATA
                float3 worldPos;
            float3 viewDir;
            float4 screenPos;
            float3 normal;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        samplerCUBE _Cube;
        float _ReflAmount;

        float _SunIntensity;
        float _SpecularPower;
        float _SpecularFalloff;

        sampler2D _DetailTex;
        float4 _DetailTex_ST;
        float _DetailOpacity;
        float _DetailCutoff;
        float _DetailFuzziness;

        float4 _GradientTop;
        float4 _GradientBot;

        sampler2D _BumpTex;
        float _BumpStrength;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            // Reflection
            /*half3 worldViewDir = normalize(UnityWorldSpaceViewDir(IN.worldPos));
            float3 viewRefl = reflect(-worldViewDir, IN.worldNormal);
            float4 reflectionColor = texCUBE(_Cube, viewRefl);
            o.Emission = reflectionColor.rgb * _ReflAmount;*/

            half3 worldViewDir = normalize(UnityWorldSpaceViewDir(IN.worldPos)); //Direction of ray from the camera towards the object surface
            half3 reflection = reflect(-worldViewDir, IN.worldNormal); // Direction of ray after hitting the surface of object
            /*If Roughness feature is not needed : UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflection) can be used instead.
            It chooses the correct LOD value based on camera distance*/
            half4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, 1 - _Glossiness); //UNITY_SAMPLE_TEXCUBE_LOD('cubemap', 'sample coordinate', 'map-map level')
            half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

            if (IN.worldNormal.y > 0) 
            {
                o.Emission = skyColor;

                // Detail (Screen space)
                float2 detailUV = IN.screenPos.xy / IN.screenPos.w;
                detailUV = detailUV * _DetailTex_ST.xy + _DetailTex_ST.zw;
                float detail = tex2D(_DetailTex, detailUV).r;
                detail = saturate(smoothstep(_DetailCutoff, _DetailCutoff + _DetailFuzziness, detail));
                float3 detailColor = detail * lerp(_GradientTop, _GradientBot, detailUV.y);
                detailColor = max(detailColor, o.Emission);

                o.Emission = lerp(o.Emission, detailColor, _DetailOpacity);
            }
           

            // Normal map
            //o.Normal = UnpackScaleNormal(tex2D(_BumpTex, IN.uv_MainTex), _BumpStrength);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
