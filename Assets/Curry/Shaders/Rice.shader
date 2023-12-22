Shader "Custom/Rice"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _ColorDark ("Color Dark", Color) = (1,1,1,1)

        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        [Header(Rim)][Space]
        _FresnelColor("Rim Color", Color) = (1,1,1,1)
        _FresnelPower("Rim Power", Range(0,10)) = 1
        _FresnelStrength("Rim Strength", Float) = 1
        
        [Header(SSS)][Space]
        _SSSAmbient("SSS Ambient Color", Color) = (1,1,1,1)
        _SSSDistortion("Translucency Distortion", Range(0,1)) = 1
        _SSSScale("Translucency Scale", Range(0, 10)) = 1
        _SSSPower("Translucency Power", Range(0.01,10)) = 1
        _SSSAttenuation("SSS Attenuation", Range(0,1)) = 1
        _SSSThickness("SSS Thickness", Range(0,1)) = 0.5
        
        [Header(Noise)][Space]
        _NoiseTex ("Noise", 2D) = "white" {}
        _NoiseCutoff ("Noise Cutoff", Range(0,1)) = 0
        _NoiseBlend ("Noise Smoothness", Range(0, 0.2)) = 0.05
    }
    CGINCLUDE
    #include "RGBShadersShared.cginc"
    #include "RGBLighting.cginc"

    struct Input
    {
        float2 uv_MainTex;
        float3 worldPos;
        float3 worldNormal; INTERNAL_DATA
        float3 viewDir;
        float3 objPos;
    };

    sampler2D _MainTex;
    half _Glossiness;
    half _Metallic;
    
    fixed4 _Color;
    fixed4 _ColorDark;

    void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            float3 vertex = v.vertex;
            o.objPos = vertex;
            //o.objPos.y = (v.vertex.y + 1) * 0.5;
        }
    
    // Lighting
    inline fixed4 LightingRice(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
    {
        //return float4(s.Albedo, 1);

        // PBR
        fixed4 pbr = LightingStandard(s, viewDir, gi);

        float3 L = gi.light.dir;
        float3 V = viewDir;
        float3 N = s.Normal;

        // SSS
        float3 sss = gi.light.color * SSS(N, L, V);

        pbr.rgb = saturate(pbr.rgb + sss);

        return pbr;
    }

    void LightingRice_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi) {
        gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
    }

    // Grunge
    sampler2D _NoiseTex;
    float4 _NoiseTex_ST;
    float _NoiseCutoff;
    float _NoiseBlend;

    float CalculateGrungeNoise(float3 worldPos, float3 worldNormal)
    {
        // Top
        float noiseSampleTop = tex2D(_NoiseTex, worldPos.xz * _NoiseTex_ST.xy + _NoiseTex_ST.zw);
        float noiseTop = smoothstep(_NoiseCutoff, _NoiseCutoff + _NoiseBlend, noiseSampleTop);
        noiseTop = lerp(1, noiseTop, (worldNormal.y));
        
        // Front
        float noiseSampleFront = tex2D(_NoiseTex, worldPos.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw);
        float noiseFront = smoothstep(_NoiseCutoff, _NoiseCutoff + _NoiseBlend, noiseSampleFront);
        noiseFront = lerp(1, noiseFront, (worldNormal.z));

        // Side
        float noiseSampleSide = tex2D(_NoiseTex, worldPos.yz * _NoiseTex_ST.xy + _NoiseTex_ST.zw);
        float noiseSide = smoothstep(_NoiseCutoff, _NoiseCutoff + _NoiseBlend, noiseSampleSide);
        noiseSide = lerp(1, noiseSide, (worldNormal.x));

        float noise = saturate(noiseFront * noiseSide * noiseTop);
        return noise;
    }
    
    ENDCG
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Rice fullforwardshadows vertex:vert
        #pragma target 4.0

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            //o.Normal = UnpackScaleNormal(tex2D(_BumpTex, IN.uv_MainTex * _BumpTex_ST.xy + _BumpTex_ST.zw), _BumpStrength);

            // Noise
            {
                float noise = CalculateGrungeNoise(IN.worldPos, (IN.worldNormal));
                o.Albedo = lerp(_ColorDark, _Color, 1 - noise);

                //o.Emission = CalculateWorldNormal(IN.worldNormal);
            }
        
            // Rim
            o.Emission += FresnelColor(o.Normal, IN.viewDir);

            thickness = _SSSThickness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
