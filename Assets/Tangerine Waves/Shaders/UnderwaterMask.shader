Shader "Hidden/UnderwaterMask"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}

        [Header(Waves)]
        _WaveA("Wave A (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
        _WaveB("Wave B", Vector) = (0,1,0.25,20)

        _ViewOffset ("View Offset", Float) = 0
    }

    CGINCLUDE
        #include "UnityCG.cginc"

        //Current camera
        #define NEAR_PLANE _ProjectionParams.y
        #define ASPECT _ScreenParams.x / _ScreenParams.y
        #define CAM_FOV unity_CameraInvProjection._m11
        #define CAM_POS _WorldSpaceCameraPos
        #define CAM_RIGHT unity_WorldToCamera[0].xyz //Possibly flipped as well, but doesn't matter
        #define CAM_UP unity_WorldToCamera[1].xyz
        //The array variant is flipped when stereo rendering is in use. Using the camera center forward vector also works for VR
        #define CAM_FWD -UNITY_MATRIX_V[2].xyz

        float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
        {
            float steepness = wave.z;
            float wavelength = wave.w;
            float k = 2 * UNITY_PI / wavelength;
            float c = sqrt(9.8 / k);
            float s = max(abs(wave.x), abs(wave.y));
            float2 d = normalize(wave.xy);
            float f = k * (dot(d, p.xz) - c * _Time.y * s);
            float a = steepness / k;

            tangent += float3(
                -d.x * d.x * (steepness * sin(f)),
                d.x * (steepness * cos(f)),
                -d.x * d.y * (steepness * sin(f))
                );
            binormal += float3(
                -d.x * d.y * (steepness * sin(f)),
                d.y * (steepness * cos(f)),
                -d.y * d.y * (steepness * sin(f))
                );
            return float3(
                d.x * (a * cos(f)),
                a * sin(f),
                d.y * (a * cos(f))
                );
        }

        // Waves
        float4 _WaveA;
        float4 _WaveB;

        // camera
        float4x4 Ocean_InverseViewMatrix;
        float4x4 Ocean_InverseProjectionMatrix;

        uniform sampler2D _CameraDepthTexture;

        uniform float WaterLevel;

        float _ViewOffset;

        float3 SampleDisplacement(float2 worldXZ)
        {
            float3 gridPoint = float3(worldXZ.x, 0, worldXZ.y);
            float3 tangent = float3(1, 0, 0);
            float3 binormal = float3(0, 0, 1);
            float3 p = gridPoint;
            p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
            p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);

            return p;
        }

        float SampleHeight(float2 worldPos)
        {
            float3 displacement = SampleDisplacement(worldPos);
            //displacement = SampleDisplacement(worldPos - displacement.xz);
            //displacement = SampleDisplacement(worldPos - displacement.xz);
            //displacement = SampleDisplacement(worldPos - displacement.xz);
            //displacement = SampleDisplacement(worldPos - displacement.xz);


            return displacement.y
                + WaterLevel;
        }

    ENDCG

    SubShader
    {
        // 0 - Mask
	    Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag

            float4 frag(v2f_img input) : SV_Target
            {
                float4 positionCS = float4(input.uv * 2 - 1, UNITY_NEAR_CLIP_VALUE, 1);
                float4 positionVS = mul(Ocean_InverseProjectionMatrix, positionCS);
                positionVS.xyz += NEAR_PLANE * _ViewOffset * CAM_FWD;

                positionVS = positionVS / positionVS.w;
                float4 positionWS = mul(Ocean_InverseViewMatrix, positionVS);
                // Sample height
                float waterHeight = SampleHeight(positionWS.xz);

                //return positionWS.y > waterHeight;

                //float submergence = positionWS.y - waterHeight + 0.5;
                float submergence = positionWS.y - waterHeight + 0.5;


                return float4(submergence.rrr, 1);
            }
            ENDCG
        }
    }
}
