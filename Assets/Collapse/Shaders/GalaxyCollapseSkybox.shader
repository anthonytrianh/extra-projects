Shader "Anthony/Sky/Galaxy Collapse Skybox"
{
    Properties
    {
        [Header(SkyboxBase)][Space]
        _Tint("Tint Color", Color) = (.5, .5, .5, .5)
        [Gamma] _Exposure("Exposure", Range(0, 8)) = 1.0
        _Rotation("Rotation", Range(0, 360)) = 0
        [NoScaleOffset] _Tex("Cubemap   (HDR)", Cube) = "grey" {}

        [Header(Collapse)][Space]
        [NoScaleOffset] _MaskTex ("Collapse Mask (HDR)", Cube) = "black" {}
        _MaskExp ("Mask Exponent", Float) = 1.7
        _BackgroundTex ("Background Texture", 2D) = "white" {}
        _BackgroundOpacity ("Background Opacity", Range(0,1)) = 1
        _BackgroundSpeed ("Background Motion", Vector) = (0, 0, 0, 0)
        _BackgroundSecondary ("Background Secondary", 2D) = "white" {}
        _BackgroundSecondarySpeed ("Background Secondary Speed", Vector) = (-0.5, 0, 0, 0)
        _BackgroundSecondaryOpacity ("Background Secondary Opacity", Range(0, 1)) = 0.5

        [HDR] _GradientTop("Gradient Top", Color) = (1,1,1,1)
        [HDR] _GradientBottom("Gradient Bottom", Color) = (0,0,0,1)

        [Header(Distortion)][Space]
        [NoScaleOffset] _DistortionTex("Distortion Texture", 2D) = "black" {}
        _DistortionStrength ("Distortion Strength", Float) = 0.05
        _DistortionParams1 ("Distortion Speed 1 (XY) Tiling (ZW)", Vector) = (0.3, 0.2, 0, 0)
        _DistortionParams2 ("Distortion Speed 2 (XY) Tiling (ZW)", Vector) = (0.18, -0.32, 0, 0)

        [Header(Kaleidoscope)][Space]
        _SegmentCount ("Kaleidoscope Segments", Int) = 2

    }
    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
        Cull Off ZWrite Off

        Pass {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"

            samplerCUBE _Tex;
            half4 _Tex_HDR;
            half4 _Tint;
            half _Exposure;
            float _Rotation;

            samplerCUBE _MaskTex;
            half4 _MaskTex_HDR;
            float _MaskExp;
            sampler2D _BackgroundTex;
            float4 _BackgroundTex_ST;
            float4 _BackgroundSpeed;
            float _BackgroundOpacity;

            sampler2D _BackgroundSecondary;
            float4 _BackgroundSecondary_ST;
            float4 _BackgroundSecondarySpeed;
            float _BackgroundSecondaryOpacity;

            float4 _GradientTop;
            float4 _GradientBottom;

            sampler2D _DistortionTex;
            float4 _DistortionTex_ST;
            float _DistortionStrength;
            float4 _DistortionParams1;
            float4 _DistortionParams2;
            
            int _SegmentCount;

            float3 RotateAroundYInDegrees(float3 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }

            struct appdata_t {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
                float4 screenPos : TEXCOORD1;
            };

            v2f vert(appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                float3 rotated = RotateAroundYInDegrees(v.vertex, _Rotation);
                o.vertex = UnityObjectToClipPos(rotated);
                o.texcoord = v.vertex.xyz;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Base sky
                half4 tex = texCUBE(_Tex, i.texcoord);
                half3 c = DecodeHDR(tex, _Tex_HDR);
                c = c * _Tint.rgb * unity_ColorSpaceDouble.rgb;
                c *= _Exposure;

                // Screen uvs
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                
                // Collapse
                float2 d1 = tex2D(_DistortionTex, screenUV * _DistortionParams1.zw + _Time.y * _DistortionParams1.xy);
                float2 d2 = tex2D(_DistortionTex, screenUV * _DistortionParams2.zw + _Time.y * _DistortionParams2.xy);
                float2 distortion = (d1 + d2) * _DistortionStrength;
                
                float2 maskUV = i.texcoord + distortion;
                half4 mask = texCUBE(_MaskTex, float3(maskUV, i.texcoord.z));
                mask = pow(mask, _MaskExp);

                // Background
                // Kaleidoscope
                float2 kuv = (screenUV + distortion * 0.25) - 0.5;
                float r = sqrt(dot(kuv, kuv));
                float a = atan2(kuv.y, kuv.x);
                float segmentAngle = UNITY_TWO_PI / _SegmentCount;
                a -= segmentAngle * floor(a / segmentAngle);
                a = min(a, segmentAngle - a);
                float2 kkuv = float2(cos(a), sin(a)) * r + 0.5;
                kkuv = max(min(kkuv, 2 - kkuv), -kkuv);

                float2 backgroundUV = kkuv * _BackgroundTex_ST.xy + _BackgroundSpeed.xy * _Time.y;
                float4 backgroundSample = tex2D(_BackgroundTex, backgroundUV);
                
                float2 backgroundSecondaryUV = screenUV * _BackgroundSecondary_ST.xy + _BackgroundSecondarySpeed.xy * _Time.y;
                float4 backgroundSecondarySample = tex2D(_BackgroundSecondary, backgroundSecondaryUV);
                backgroundSample = lerp(backgroundSample, backgroundSecondarySample, _BackgroundSecondaryOpacity);
                
                float4 backgroundColor = lerp(_GradientTop, _GradientBottom, 1 - screenUV.y);
                backgroundColor = lerp(backgroundColor, backgroundColor * backgroundSample, _BackgroundOpacity);
                c = lerp(c, backgroundColor, mask.r);

                return half4(c, 1);
            }
            ENDCG
        }
    }

    Fallback Off
}
