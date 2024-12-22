Shader "Hidden/RainOnLensImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _RainMask ("Rain Mask", 2D) = "white" {}
        _RainMaskThreshold ("Rain Mask Threshold", Vector) = (0, 1, 0, 0)
        
        [Header(Raindrops)][Space]
        _RainDropsTex ("Rain Drops Texture", 2D) = "bump" {}
        _RainDropsDistortion ("Rain Drops Distortion", Float) = 0.01
        _RainDropsAnimSpeed ("Rain Drops Anim Speed", Float) = 1
        _RainDropsStaticPower ("Rain Drops Static Power", Float) = 10
        
        [Header(Raindrips)][Space]
        _RainDripsTex ("Rain Drips Texture", 2D) = "bump" {}
        _RainDripsScale ("Rain Drips World Scale", Float) = 0.7
        _RainDripMask ("Rain Drip Mask", 2D) = "black" {}
        _RainDripMaskScale ("Rain Drip Mask Scale", Vector) = (1, 1.05, 1, 0)
        _RainDripsSpeed ("Rain Drip Speed Min Max", Vector) = (0.25, 0.7, 0, 0)
        _RainDripsStrength ("Rain Drips Strength", Float) = 4
    }
    CGINCLUDE

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
            float4 screenPos : TEXCOORD1;
        };

        sampler2D _MainTex;
    
        sampler2D _RainMask;
        float4 _RainMask_ST;
        float4 _RainMaskThreshold;
    
        sampler2D _RainDropsTex;
        float4 _RainDropsTex_ST;
        float _RainDropsDistortion;
        float _RainDropsAnimSpeed;
        float _RainDropsStaticPower;

        sampler2D _RainDripsTex;
        float4 _RainDripsTex_ST;
        float _RainDripsScale;
        float _RainDripsStrength;
        sampler2D _RainDripMask;
        float2 _RainDripMaskScale;
        float2 _RainDripsSpeed;

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            o.screenPos = ComputeScreenPos(o.vertex);
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            // Get aspect ratio: Width / Height
            float aspectRatio = _ScreenParams.x / _ScreenParams.y;
            float2 aspect = float2(aspectRatio, 1);

            // Screen uv
            float2 screenUV = i.screenPos.xy / i.screenPos.w;
            float2 aspectUV = screenUV * aspect;
            
            // Rain Drops texture sample
            float4 rainDropsSample = tex2D(_RainDropsTex, aspectUV * _RainDropsTex_ST.xy + _RainDropsTex_ST.zw);

            // Rain drops normals
            float2 rainDropsNormals = rainDropsSample.xy * 2 - 1;

            // Temporal offset mask
            float temporalOffset = rainDropsSample.z;
            float timeOffset = frac(temporalOffset - _Time.y * _RainDropsAnimSpeed);

            // Animated drop mask in alpha channel
            float animMask = saturate(rainDropsSample.a * 2 - 1) * timeOffset;

            // 2. Static rain drops
            // Invert alpha channel for static rain drops
            float staticMask = saturate(pow((rainDropsSample.a * 2 - 0.5) * (-1), _RainDropsStaticPower));

            // Final rain mask: combine static and animated
            float rainDropsFinalMask = animMask + staticMask;

            // Rain drips
            float4 rainDripsSample = tex2D(_RainDripsTex, aspectUV * _RainDripsScale * _RainDripsTex_ST.xy + _RainDripsTex_ST.zw);
            
            // Round the mask so the drops looks more condensed
            float dripsDropsMask = round(rainDripsSample.b);

            // Temporal offset mask contained in dripsSample alpha
            float dripsTemporalOffset = rainDripsSample.a;
            float dripsTime = _Time.y + dripsTemporalOffset;

            // Drips movement
            float2 dripsMovement1 = lerp(_RainDripsSpeed.x, _RainDripsSpeed.y, dripsTemporalOffset);
            float2 dripsMovement = dripsMovement1 * dripsTime;
            
            // Drips animated mask
            float2 rainDripMaskUV = aspectUV * _RainDripMaskScale;
            float drips = tex2D(_RainDripMask, rainDripMaskUV + dripsMovement).r;
            drips *= dripsDropsMask;
            
            // Drips Normals
            float2 dripsNormalOffset = (rainDripsSample.xy * 2 - 1) * _RainDripsStrength * drips;
            float3 dripsNormals = float3(dripsNormalOffset, 1);
            
            // Rain distortion
            float2 rainDistortion =
                rainDropsNormals.xy * _RainDropsDistortion +
                dripsNormals.xy * _RainDropsDistortion;
            rainDistortion *= rainDropsFinalMask;

            // Rain mask
            float rainMask = tex2D(_RainMask, i.uv * aspect * _RainMask_ST.xy + _RainMask_ST.zw).r;
            rainMask = saturate(smoothstep(_RainMaskThreshold.x, _RainMaskThreshold.y, rainMask));
            
            // Sample scene color
            float2 screenUVDistorted = screenUV;
            screenUVDistorted += rainDistortion * rainMask;
            
            fixed4 col = tex2D(_MainTex, screenUVDistorted);
            return col;
        }
    
    ENDCG
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

           
            ENDCG
        }
    }
}
