Shader "Anthony/Surface/Triplanar/RGBStandardTriplanarWorldNormals"
{
    Properties
    {
        [Header(Diffuse)] [Space]
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        
        [Header(Metallic)] [Space]
        _MetallicTex ("Metallic Tex", 2D) = "white" {}
        _Metallic("Metallic", Range(0,1)) = 0.0

        [Header(Glossiness)] [Space]
        _RoughnessTex ("Roughness Tex", 2D) = "black" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5

        [Header(Normal)] [Space]
        [NoScaleOffset] _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpStrength("Bump Strength", Float) = 1

        [Header(HeightParallax)] [Space]
        [Toggle(_PARALLAX)] _UseParallax ("Height?", Int) = 0
        [NoScaleOffset] _ParallaxTex("Height Tex", 2D) = "white" {}
        _Height ("Height", Float) = 0

        _CullMode("Cull Mode", Float) = 0

        [Toggle(VERT_GRADIENT)] _VerticalGradient("Veritcal Gradient Color?", Float) = 0
        _ColorTop("Color Top", Color) = (1,1,1,1)
        _ColorBot("Color Bottom", Color) = (0.5, 0.5, 0.5, 1)

        [Header(Debug)] [Space]
        [Toggle(DEBUG_GRID)] _DebugGrid ("Show Debug Grid", Int) = 0
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 200

            Cull[_CullMode]

            CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma surface surf Standard fullforwardshadows
            #pragma vertex vert
            #pragma shader_feature _PARALLAX
            #pragma shader_feature VERT_GRADIENT

            #pragma target 4.5

            #include "RGBShadersShared.cginc"

            struct Input
            {
                float2 uv;
                float3 worldPos;
                float3 worldNormal; INTERNAL_DATA
                float3 viewDir;
                float3 objPos;
            };

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed4 _Color;

            sampler2D _MetallicTex;
            half _Metallic;

            sampler2D _RoughnessTex;
            half _Glossiness;

            // Parallax
            sampler2D _ParallaxTex;
            float _Height;

            // Vertical Gradient
            float4 _ColorTop, _ColorBot;

            float2 GetParallaxOffset(sampler2D parallaxTex, float2 uv, float height, float3 viewDir) 
            {
                float parallaxSample = tex2D(parallaxTex, uv).r;
                return ParallaxOffset(parallaxSample, height, viewDir);
            }

            void vert(inout appdata_full v, out Input o)
            {
                UNITY_INITIALIZE_OUTPUT(Input, o);

                o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);

                #ifdef _CAMERA_DITHER
                    o.eyeDepth = -UnityObjectToViewPos(v.vertex.xyz).z;
                #endif

                o.objPos = v.vertex;
                o.objPos.y = (v.vertex.y + 1) * 0.5;
            }

            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                fixed4 c;
                // Diffuse
                float3 W = IN.worldPos;

                float2 topUV = W.xz * _MainTex_ST.xy + _MainTex_ST.zw;
                float2 frontUV = W.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                float2 sideUV = W.yz * _MainTex_ST.xy + _MainTex_ST.wz;

                #ifdef _PARALLAX
                topUV += GetParallaxOffset(_ParallaxTex, topUV, _Height, IN.viewDir);
                frontUV += GetParallaxOffset(_ParallaxTex, frontUV, _Height, IN.viewDir);
                sideUV += GetParallaxOffset(_ParallaxTex, sideUV, _Height, IN.viewDir);
                #endif

                fixed3 topCol = tex2D(_MainTex, topUV);
                fixed3 frontCol = tex2D(_MainTex, frontUV);
                fixed3 sideCol = tex2D(_MainTex, sideUV);

                // Normals
                fixed3 N = WorldNormalVector(IN, o.Normal);
                float3 blendNormal = saturate(pow(N * 1.4, 4));
                float3 worldNormal = pow(abs(N), 2);

                fixed3 topNormal = UnpackScaleNormal(tex2D(_BumpTex, topUV), _BumpStrength);
                fixed3 frontNormal = UnpackScaleNormal(tex2D(_BumpTex, frontUV), _BumpStrength);
                fixed3 sideNormal = UnpackScaleNormal(tex2D(_BumpTex, sideUV), _BumpStrength);

                fixed3 blendedNormals = topNormal * worldNormal.y + sideNormal * worldNormal.x + frontNormal * worldNormal.z;
                
                // Albedo
                fixed3 y = lerp(0, topCol, abs(worldNormal.y));
                fixed3 z = lerp(0, frontCol, abs(worldNormal.z));
                fixed3 x = lerp(0, sideCol, abs(worldNormal.x));

                float4 shading = _Color;
#if VERT_GRADIENT
                shading = lerp(_ColorTop, _ColorBot, 1 - IN.objPos.y);
#endif

                c.rgb = (x + y + z) * shading.rgb;
                c.a = 1;

                o.Albedo = c.rgb;
                o.Normal = blendedNormals;
                    // Unnecessary since this is already a surface shader
                    //SimpleTriplanarNormals(W, worldNormal, worldNormal);

                // Apply global brightness
                APPLY_GLOBAL_BRIGHTNESS(c.rgb);

                // Normal Cube
                APPLY_NORMAL_CUBE_EFFECT(IN.worldPos, o.Normal);

                // Metallic
                fixed metalTop = tex2D(_MetallicTex, topUV).r;
                fixed metalFront = tex2D(_MetallicTex, frontUV).r;
                fixed metalSide = tex2D(_MetallicTex, sideUV).r;

                fixed metal = metalTop * worldNormal.y + metalSide * worldNormal.x + metalFront * worldNormal.z;
                metal *= _Metallic;

                // Roughness
                fixed roughTop = tex2D(_RoughnessTex, topUV).r;
                fixed roughFront = tex2D(_RoughnessTex, frontUV).r;
                fixed roughSide = tex2D(_RoughnessTex, sideUV).r;

                fixed rough = roughTop * worldNormal.y + roughSide * worldNormal.x + roughFront * worldNormal.z;

                o.Metallic = metal;
                o.Smoothness = (1 - rough) * _Glossiness;
                o.Alpha = c.a;

                //o.Emission = float3(0, IN.objPos.y, 0);
            }
            ENDCG
        }
            FallBack "Diffuse"
}
