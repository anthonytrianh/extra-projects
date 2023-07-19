// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASM_FBM"
{
	Properties
	{
		_Scale("Scale", Float) = 6
		_Iterations("Iterations", Int) = 16
		_RotationStep("RotationStep", Float) = 5
		_AnimSpeed("AnimSpeed", Float) = 3.5
		_RippleStrength("RippleStrength", Float) = 0.9
		_RippleMaxFrequency("RippleMaxFrequency", Float) = 1.4
		_RippleSpeed("RippleSpeed", Float) = 5
		_Brightness("Brightness", Float) = 2
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		_NormalStrength("NormalStrength", Float) = 0
		[HDR]_FractalColorA("FractalColorA", Color) = (0,0,0,0)
		[HDR]_FractalColorB("FractalColorB", Color) = (0,0,0,0)
		_Radius("Radius", Range( 0 , 1)) = 0
		_WaveCount("WaveCount", Int) = 0
		_CircleMaskRadius("CircleMaskRadius", Float) = 0
		_RotateSpeed("RotateSpeed", Float) = 1
		_NoiseTexture("NoiseTexture", 2D) = "white" {}
		_NoiseOpacity("NoiseOpacity", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#include "FBMInclude.cginc"
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float2 uv_texcoord;
		};

		uniform float _RotateSpeed;
		uniform float _Radius;
		uniform int _WaveCount;
		uniform float _Scale;
		uniform float _RotationStep;
		uniform int _Iterations;
		uniform float _AnimSpeed;
		uniform float _RippleStrength;
		uniform float _RippleMaxFrequency;
		uniform float _RippleSpeed;
		uniform float _Brightness;
		uniform float _NormalStrength;
		uniform float4 _FractalColorA;
		uniform float4 _FractalColorB;
		uniform sampler2D _NoiseTexture;
		SamplerState sampler_NoiseTexture;
		uniform float _NoiseOpacity;
		uniform float _CircleMaskRadius;
		uniform float _Smoothness;


		float HexSDFMasking24( float2 uv, float radius, int waveCount, out float sdf, out float mask )
		{
			HexSdfMask(uv, radius, waveCount, sdf, mask);
			return 0;
		}


		float Fractal2( float2 uv, float scale, float scaleMultStep, float rotationStep, int iterations, float uvAnimationSpeed, float rippleStrength, float rippleMaxFrequency, float rippleSpeed, float brightness )
		{
			 return GetAnimatedOrganicFractal(
			    scale, scaleMultStep, rotationStep, iterations, uv ,uvAnimationSpeed, rippleStrength, rippleMaxFrequency, rippleSpeed, brightness);
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldPos = i.worldPos;
			float3 temp_output_16_0_g1 = ( ase_worldPos * 100.0 );
			float3 crossY18_g1 = cross( ase_worldNormal , ddy( temp_output_16_0_g1 ) );
			float3 worldDerivativeX2_g1 = ddx( temp_output_16_0_g1 );
			float dotResult6_g1 = dot( crossY18_g1 , worldDerivativeX2_g1 );
			float crossYDotWorldDerivX34_g1 = abs( dotResult6_g1 );
			float mulTime53 = _Time.y * _RotateSpeed;
			float cos50 = cos( mulTime53 );
			float sin50 = sin( mulTime53 );
			float2 rotator50 = mul( i.uv_texcoord - float2( 0.5,0.5 ) , float2x2( cos50 , -sin50 , sin50 , cos50 )) + float2( 0.5,0.5 );
			float2 uv24 = rotator50;
			float radius24 = _Radius;
			int waveCount24 = _WaveCount;
			float sdf24 = 0.0;
			float mask24 = 0.0;
			float localHexSDFMasking24 = HexSDFMasking24( uv24 , radius24 , waveCount24 , sdf24 , mask24 );
			float temp_output_30_0 = ( 1.0 - mask24 );
			float2 uv2 = i.uv_texcoord;
			float scale2 = _Scale;
			float scaleMultStep2 = temp_output_30_0;
			float rotationStep2 = _RotationStep;
			int iterations2 = _Iterations;
			float uvAnimationSpeed2 = _AnimSpeed;
			float rippleStrength2 = _RippleStrength;
			float rippleMaxFrequency2 = _RippleMaxFrequency;
			float rippleSpeed2 = _RippleSpeed;
			float brightness2 = _Brightness;
			float localFractal2 = Fractal2( uv2 , scale2 , scaleMultStep2 , rotationStep2 , iterations2 , uvAnimationSpeed2 , rippleStrength2 , rippleMaxFrequency2 , rippleSpeed2 , brightness2 );
			float lerpResult41 = lerp( 1.0 , temp_output_30_0 , localFractal2);
			float temp_output_20_0_g1 = ( ( 1.0 - lerpResult41 ) * _NormalStrength );
			float3 crossX19_g1 = cross( ase_worldNormal , worldDerivativeX2_g1 );
			float3 break29_g1 = ( sign( crossYDotWorldDerivX34_g1 ) * ( ( ddx( temp_output_20_0_g1 ) * crossY18_g1 ) + ( ddy( temp_output_20_0_g1 ) * crossX19_g1 ) ) );
			float3 appendResult30_g1 = (float3(break29_g1.x , -break29_g1.y , break29_g1.z));
			float3 normalizeResult39_g1 = normalize( ( ( crossYDotWorldDerivX34_g1 * ase_worldNormal ) - appendResult30_g1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 worldToTangentDir42_g1 = mul( ase_worldToTangent, normalizeResult39_g1);
			o.Normal = worldToTangentDir42_g1;
			float4 appendResult21 = (float4(_FractalColorA.r , _FractalColorA.g , _FractalColorA.b , 0.0));
			float4 appendResult23 = (float4(_FractalColorB.r , _FractalColorB.g , _FractalColorB.b , 0.0));
			float4 lerpResult22 = lerp( appendResult21 , appendResult23 , ( sdf24 * localFractal2 ));
			float4 temp_output_4_0 = ( temp_output_30_0 * lerpResult22 );
			float2 uv_TexCoord56 = i.uv_texcoord * float2( 2,2 );
			float2 panner57 = ( 1.0 * _Time.y * float2( 0.1,0.1 ) + uv_TexCoord56);
			float4 lerpResult61 = lerp( temp_output_4_0 , ( temp_output_4_0 * tex2D( _NoiseTexture, panner57 ).r ) , _NoiseOpacity);
			float2 temp_cast_0 = (1.0).xx;
			o.Emission = ( lerpResult61 * ( 1.0 - saturate( ( length( ( ( i.uv_texcoord * float2( 2,2 ) ) - temp_cast_0 ) ) - _CircleMaskRadius ) ) ) ).xyz;
			o.Smoothness = _Smoothness;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
271.3333;132.6667;1280;651;2491.808;1287.724;2.959744;True;True
Node;AmplifyShaderEditor.RangedFloatNode;51;-1826.547,-717.5221;Inherit;False;Property;_RotateSpeed;RotateSpeed;16;0;Create;True;0;0;False;0;False;1;-0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;5;-1495.767,-371.6198;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;53;-1690.547,-654.5221;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;28;-1216.625,-682.8199;Inherit;False;Property;_WaveCount;WaveCount;14;0;Create;True;0;0;False;0;False;0;4;0;1;INT;0
Node;AmplifyShaderEditor.RotatorNode;50;-1481.547,-769.5221;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;26;-1489.885,-582.3495;Inherit;False;Property;_Radius;Radius;13;0;Create;True;0;0;False;0;False;0;0.62;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;31;-328.4914,-1098.599;Inherit;False;1060.792;554.6407;Radial Mask;10;37;36;35;33;32;39;45;47;48;40;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CustomExpressionNode;24;-1088.054,-559.7332;Inherit;False;HexSdfMask(uv, radius, waveCount, sdf, mask)@$return 0@;1;False;5;True;uv;FLOAT2;0,0;In;;Inherit;False;True;radius;FLOAT;1;In;;Inherit;False;True;waveCount;INT;1;In;;Inherit;False;True;sdf;FLOAT;0;Out;;Inherit;False;True;mask;FLOAT;0;Out;;Inherit;False;HexSDFMasking;True;False;0;5;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;INT;1;False;3;FLOAT;0;False;4;FLOAT;0;False;3;FLOAT;0;FLOAT;4;FLOAT;5
Node;AmplifyShaderEditor.RangedFloatNode;14;-1211.028,423.0126;Inherit;False;Property;_Brightness;Brightness;8;0;Create;True;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;9;-1425.028,78.01257;Inherit;False;Property;_RotationStep;RotationStep;3;0;Create;True;0;0;False;0;False;5;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;32;-312.7565,-1046.021;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;10;-1429.028,191.0126;Inherit;False;Property;_AnimSpeed;AnimSpeed;4;0;Create;True;0;0;False;0;False;3.5;3.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;11;-1553.028,264.0126;Inherit;False;Property;_RippleStrength;RippleStrength;5;0;Create;True;0;0;False;0;False;0.9;0.8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;7;-1567.124,118.599;Inherit;False;Property;_Iterations;Iterations;1;0;Create;True;0;0;False;0;False;16;13;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-1570.737,-104.0944;Inherit;False;Property;_Scale;Scale;0;0;Create;True;0;0;False;0;False;6;5.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;30;-862.4207,-384.4742;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-1440.028,378.0125;Inherit;False;Property;_RippleSpeed;RippleSpeed;7;0;Create;True;0;0;False;0;False;5;3.28;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-1343.028,302.0125;Inherit;False;Property;_RippleMaxFrequency;RippleMaxFrequency;6;0;Create;True;0;0;False;0;False;1.4;9;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;35;87.2434,-938.0212;Inherit;False;Constant;_Float0;Float 0;15;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;2;-906.1345,-29.27362;Inherit;False; return GetAnimatedOrganicFractal($    scale, scaleMultStep, rotationStep, iterations, uv ,uvAnimationSpeed, rippleStrength, rippleMaxFrequency, rippleSpeed, brightness)@;1;False;10;True;uv;FLOAT2;0,0;In;;Inherit;False;True;scale;FLOAT;6;In;;Inherit;False;True;scaleMultStep;FLOAT;1.2;In;;Inherit;False;True;rotationStep;FLOAT;5;In;;Inherit;False;True;iterations;INT;16;In;;Inherit;False;True;uvAnimationSpeed;FLOAT;3.5;In;;Inherit;False;True;rippleStrength;FLOAT;0.9;In;;Inherit;False;True;rippleMaxFrequency;FLOAT;1.4;In;;Inherit;False;True;rippleSpeed;FLOAT;5;In;;Inherit;False;True;brightness;FLOAT;2;In;;Inherit;False;Fractal;True;False;0;10;0;FLOAT2;0,0;False;1;FLOAT;6;False;2;FLOAT;1.2;False;3;FLOAT;5;False;4;INT;16;False;5;FLOAT;3.5;False;6;FLOAT;0.9;False;7;FLOAT;1.4;False;8;FLOAT;5;False;9;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;20;-1270.529,-973.7798;Inherit;False;Property;_FractalColorB;FractalColorB;12;1;[HDR];Create;True;0;0;False;0;False;0,0,0,0;0.5836707,0,0.6509804,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-48.75658,-1035.021;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;2,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;19;-1267.78,-1163.577;Inherit;False;Property;_FractalColorA;FractalColorA;11;1;[HDR];Create;True;0;0;False;0;False;0,0,0,0;1.205873,0.7302741,1.835294,0.7882353;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;56;-348.5848,-234.4524;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;2,2;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;33;219.2434,-1050.021;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT;0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-788.4064,-692.8809;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;21;-958.5295,-1137.78;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;23;-955.5295,-936.7798;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-212.2706,-641.4027;Inherit;False;Property;_CircleMaskRadius;CircleMaskRadius;15;0;Create;True;0;0;False;0;False;0;0.11;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;22;-774.5295,-1013.78;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LengthOpNode;37;-224.319,-875.9166;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;57;-345.9186,-114.8535;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,0.1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;41;-725.4619,-196.8656;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;59;-99.94305,-178.9051;Inherit;True;Property;_NoiseTexture;NoiseTexture;17;0;Create;True;0;0;False;0;False;-1;None;d07ecd5df831b024298e423692a38571;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;47;-8.544846,-751.5253;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;4;-491.1368,-500.9832;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT4;1,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-625.8035,307.8806;Inherit;False;Property;_NormalStrength;NormalStrength;10;0;Create;True;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;62;179.6699,-326.4048;Inherit;False;Property;_NoiseOpacity;NoiseOpacity;18;0;Create;True;0;0;False;0;False;0;0.713;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;60;-81.7498,-336.9056;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.OneMinusNode;42;-562.7754,-182.8066;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;48;162.1442,-739.1366;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;61;205.6699,-475.4047;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;-416.4832,223.3941;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;39;327.969,-661.0859;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-1577.903,6.043915;Inherit;False;Property;_ScaleMultiplierStep;ScaleMultiplierStep;2;0;Create;True;0;0;False;0;False;1.2;1.26;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-478.2032,455.4806;Inherit;False;Property;_Smoothness;Smoothness;9;0;Create;True;0;0;False;0;False;0;0.562;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;528.4879,-628.6971;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;1;-165.6076,263.8616;Inherit;False;Normal From Height;-1;;1;1942fe2c5f1a1f94881a33d532e4afeb;0;1;20;FLOAT;0;False;2;FLOAT3;40;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;557.4718,-112.6995;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;ASM_FBM;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;1;Include;FBMInclude.cginc;False;;Custom;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;53;0;51;0
WireConnection;50;0;5;0
WireConnection;50;2;53;0
WireConnection;24;0;50;0
WireConnection;24;1;26;0
WireConnection;24;2;28;0
WireConnection;30;0;24;5
WireConnection;2;0;5;0
WireConnection;2;1;6;0
WireConnection;2;2;30;0
WireConnection;2;3;9;0
WireConnection;2;4;7;0
WireConnection;2;5;10;0
WireConnection;2;6;11;0
WireConnection;2;7;12;0
WireConnection;2;8;13;0
WireConnection;2;9;14;0
WireConnection;36;0;32;0
WireConnection;33;0;36;0
WireConnection;33;1;35;0
WireConnection;43;0;24;4
WireConnection;43;1;2;0
WireConnection;21;0;19;1
WireConnection;21;1;19;2
WireConnection;21;2;19;3
WireConnection;23;0;20;1
WireConnection;23;1;20;2
WireConnection;23;2;20;3
WireConnection;22;0;21;0
WireConnection;22;1;23;0
WireConnection;22;2;43;0
WireConnection;37;0;33;0
WireConnection;57;0;56;0
WireConnection;41;1;30;0
WireConnection;41;2;2;0
WireConnection;59;1;57;0
WireConnection;47;0;37;0
WireConnection;47;1;45;0
WireConnection;4;0;30;0
WireConnection;4;1;22;0
WireConnection;60;0;4;0
WireConnection;60;1;59;1
WireConnection;42;0;41;0
WireConnection;48;0;47;0
WireConnection;61;0;4;0
WireConnection;61;1;60;0
WireConnection;61;2;62;0
WireConnection;17;0;42;0
WireConnection;17;1;16;0
WireConnection;39;0;48;0
WireConnection;40;0;61;0
WireConnection;40;1;39;0
WireConnection;1;20;17;0
WireConnection;0;1;1;40
WireConnection;0;2;40;0
WireConnection;0;4;15;0
ASEEND*/
//CHKSM=1B718946E1FA32763282D36127CD9D8075C41A23