#ifndef RGB_SHARED_INCLUDED
#define RGB_SHARED_INCLUDED
#include "UnityCG.cginc"
#include "Lighting.cginc"


///////////////////////////////////////////////////////
// Global brightness
// ** For cinematic, abilities that affect everything
//		except the casting unit and affected units

float _GlobalBrightness;

#define APPLY_GLOBAL_BRIGHTNESS(albedo) albedo.rgb *= _GlobalBrightness;

//////////////////////////////////////////////////////
// Debug World Grid
// ** Shows grid overlay for NxN dimension tiles for
//    map building
uniform float _GridTileSize;

////////////////////////////////////////
// Space functions
//

inline float4 CalculateWorldPos(float4 vertex)
{
	return mul(unity_ObjectToWorld, vertex);
}

inline float4 CalculateLocalPos(float4 vertex)
{
#ifdef UNITY_INSTANCING_ENABLED
	//vertex.xy *= _Flip.xy;
#endif

	float4 pos = UnityObjectToClipPos(vertex);

#ifdef PIXELSNAP_ON
	pos = UnityPixelSnap(pos);
#endif

	return pos;
}

inline half3 CalculateWorldNormal(float3 normal)
{
	return UnityObjectToWorldNormal(normal);
}

////////////////////////////////////////
// Alpha Clipping
//

uniform fixed _Cutoff;

#define ALPHA_CLIP_COLOR(pixel, color) clip((pixel.a * color.a) - _Cutoff);
#define ALPHA_CLIP(pixel) clip(pixel.a - _Cutoff);
#define ALPHA_CLIP_VALUE(value) clip(value - _Cutoff);

////////////////////////////////////////
// Normal map
//

sampler2D _BumpTex;
float4 _BumpTex_ST;
float _BumpStrength;

/** Triplanar Normal Mapping */
float3 SimpleTriplanarNormals(float3 worldPos, float3 worldNormal, float3 blend)
{
    // Triplanar uvs
    float2 uvX = worldPos.zy; // x facing plane
    float2 uvY = worldPos.xz; // y facing plane
    float2 uvZ = worldPos.xy; // z facing plane
    // Tangent space normal maps
    half3 tnormalX = UnpackScaleNormal(tex2D(_BumpTex, uvX * _BumpTex_ST.xy + _BumpTex_ST.zw), _BumpStrength);
    half3 tnormalY = UnpackScaleNormal(tex2D(_BumpTex, uvY * _BumpTex_ST.xy + _BumpTex_ST.zw), _BumpStrength);
    half3 tnormalZ = UnpackScaleNormal(tex2D(_BumpTex, uvZ * _BumpTex_ST.xy + _BumpTex_ST.zw), _BumpStrength);
    // Get the sign (-1 or 1) of the surface normal
    half3 axisSign = sign(worldNormal);
    // Flip tangent normal z to account for surface normal facing
    tnormalX.z *= axisSign.x;
    tnormalY.z *= axisSign.y;
    tnormalZ.z *= axisSign.z;
    // Swizzle tangent normals to match world orientation and triblend
    half3 blendedNormal = normalize(
    tnormalX.zyx * blend.x +
    tnormalY.xzy * blend.y +
    tnormalZ.xyz * blend.z
    );
    
    return blendedNormal;
}

#if defined(_NORMALMAP)
uniform sampler2D _BumpMap;
uniform half _BumpScale;

//half3 UnpackScaleNormal(half4 packednormal, half bumpScale)
//{
//#if defined(UNITY_NO_DXT5nm)
//		return packednormal.xyz * 2 - 1;
//#else
//		half3 normal;
//		normal.xy = (packednormal.wy * 2 - 1);
//#if (SHADER_TARGET >= 30)
//			// SM2.0: instruction count limitation
//			// SM2.0: normal scaler is not supported
//			normal.xy *= bumpScale;
//#endif
//		normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
//		return normal;
//#endif
//}		


inline half3 CalculateWorldTangent(float4 tangent)
{
	return UnityObjectToWorldDir(tangent.xyz);
}

inline half3 CalculateWorldBinormal(half3 normalWorld, half3 tangentWorld, float tangentSign)
{
	tangentSign = tangentSign * unity_WorldTransformParams.w;
	
#ifdef UNITY_INSTANCING_ENABLED
	tangentSign *= sign(_Flip.x) * sign(_Flip.y);
#endif
	
	return cross(normalWorld, tangentWorld) * tangentSign;
}

inline half3 CalculateNormalFromBumpMap(float2 texUV, half3 tangentWorld, half3 binormalWorld, half3 normalWorld)
{
	half3 localNormal = UnpackScaleNormal(tex2D(_BumpMap, texUV), _BumpScale);
	half3x3 rotation = half3x3(tangentWorld, binormalWorld, normalWorld);
	half3 normal = normalize(mul(localNormal, rotation));
	return normal;
}

#endif // _NORMALMAP


/////////////////////////////////////
// Emission
sampler2D _EmissiveTex;
float4 _EmissiveTex_ST;

float4 _EmissiveColor;
#ifdef EMISSION

#endif // EMISSION

///////////////////////////////////////////////
// Dither

#ifdef _CAMERA_DITHER /// #ifdef can only be used for one condition
uniform float _DitherFalloff;
uniform float _DitherDistance;


inline float Dither4x4Bayer(int x, int y)
{
    const float dither[16] =
    {
        1, 9, 3, 11,
				13, 5, 15, 7,
				 4, 12, 2, 10,
				16, 8, 14, 6
    };
    int r = y * 4 + x;
    return dither[r] / 16; // same # of instructions as pre-dividing due to compiler magic
}

void APPLY_DITHER(float4 screenPos, float eyeDepth)
{
    screenPos = screenPos; // NDC space (0 top left -- 1920,1080 bottom right)
    float4 screenPosNorm = screenPos / screenPos.w; // Normalized screen position (-1.0, 1.0)
    screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5; // Convert to (0, 1)
    float2 clipScreen2 = screenPosNorm.xy * _ScreenParams.xy; // Clip space
    float dither2 = Dither4x4Bayer(fmod(clipScreen2.x, 4), fmod(clipScreen2.y, 4)); // Apply Dither4x4 for every 4 pixels on the X and Y axes
    float cameraDepthFade = ((eyeDepth - _ProjectionParams.y - _DitherDistance) / _DitherFalloff); // 
    dither2 = step(dither2, cameraDepthFade); // Evaluates which pixels needed to be clipped
    ALPHA_CLIP_VALUE(dither2);
}

#endif

///////////////////////////////////////////////////////
// Environment Interactions

// Interaction
#ifdef INTERACTORS
uniform float _InteractorPositionsArraySize;
uniform float3 _InteractorPositions[100];
uniform float _InteractorRadii[100];
float _InteractorStrength;

float3 InteractorsSphereDisplacement(float3 worldPos)
{
    float3 totalSphereDisplacement = 0;
    for (int i = 0; i < _InteractorPositionsArraySize; i++)
    {
        float3 distanceToInteractor = distance(_InteractorPositions[i], worldPos);
        float dispRadius = 1 - saturate(distanceToInteractor / _InteractorRadii[i]);
        float3 sphereDisplacement = worldPos - _InteractorPositions[i]; // compare positions to figure out which direction to displace in
        sphereDisplacement *= dispRadius; // multiplied by radius for falloff
        sphereDisplacement = clamp(sphereDisplacement.xyz * _InteractorStrength, -0.8, 0.8);

        totalSphereDisplacement += sphereDisplacement;
        totalSphereDisplacement = clamp(totalSphereDisplacement, -0.8, 0.8);
    }
    
    return totalSphereDisplacement;
}

bool CheckSpawnGrass(float3 worldPos)
{
    bool SpawnGrass = true;
    for (int i = 0; i < _InteractorPositionsArraySize; i++)
    {
        float3 Position = _InteractorPositions[i];
        if (worldPos.x <= ceil(Position.x ) && worldPos.x >= floor(Position.x) &&
            worldPos.z <= ceil(Position.z) && worldPos.z >= floor(Position.z))
        {
            SpawnGrass = false;
            break;
        }
    }

    return SpawnGrass;
}

#endif

///////////////////////////////////////////////////////
// Normal Cube
uniform float _NormalCubeArraySize;
uniform float3 _NormalCubePositions[100];
float _NormalCubePosition;

/* Inverts the normals on 1x1 spaces */
float3 NormalCubeModifyNormals(float3 worldPos, float3 normal)
{
    float3 calculatedNormal = normal;
    
    for (int i = 0; i < _NormalCubeArraySize; i++)
    {
        float3 Position = _NormalCubePositions[i];
        
        float x = Position.x;
        float z = Position.z;
        
        float2 min = float2(x - 0.5, z - 0.5);
        float2 max = float2(x + 0.5, z + 0.5);

        float cubeMask = worldPos.x >= min.x && worldPos.x <= max.x && 
                        worldPos.z >= min.y && worldPos.z <= max.y;
        
        if (cubeMask > 0)
        {
            calculatedNormal = normal.yzx;
        }
    }
    
    //float3 Position = _NormalCubePosition;
    //if (ceil(worldPos.x) >= (Position.x) && floor(worldPos.x) <= (Position.x) && 
    //    ceil(worldPos.z) >= (Position.z) && floor(worldPos.z) <= (Position.z))
    //{
    //    return normal.yzx;
    //}
    
    
    
    return calculatedNormal;
}

#define APPLY_NORMAL_CUBE_EFFECT(worldPos, normal) normal = NormalCubeModifyNormals(worldPos, normal);
#define CALC_NORMAL_CUBE_EFFECT(worldPos, normal) NormalCubeModifyNormals(worldPos, normal);

///////////////////////////////////////////////////////
// Fog of war
//
// @TODO


///////////////////////////////////////////////////////
// Shading
float ConvertToGreyscale(float3 inColor)
{
    return dot(inColor.rgb, float3(0.3, 0.59, 0.11));
}

#endif