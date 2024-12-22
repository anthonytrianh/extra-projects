#ifndef TRANSLUCENT_INCLUDED
#define TRANSLUCENT_INCLUDED

#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"

sampler2D _SSThickness;
float _SSPower;
float _SSDistortion;
float _SSScale;
float3 _SSSubColor;

inline fixed4 LightingTranslucent (SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten)
{		
    // You can remove these two lines,
    // to save some instructions. They're just
    // here for visual fidelity.
    viewDir = normalize ( viewDir );
    lightDir = normalize ( lightDir );

    // Translucency.
    half3 transLightDir = lightDir + s.Normal * _SSDistortion;
    float transDot = pow ( max (0, dot ( viewDir, -transLightDir ) ), _SSPower ) * _SSScale;
    fixed3 transLight = (atten * 2) * ( transDot ) * s.Alpha * _SSSubColor.rgb;
    fixed3 transAlbedo = s.Albedo * _LightColor0.rgb * transLight;

    // Regular BlinnPhong.
    half3 h = normalize (lightDir + viewDir);
    fixed diff = max (0, dot (s.Normal, lightDir));
    float nh = max (0, dot (s.Normal, h));
    float spec = pow (nh, s.Specular*128.0) * s.Gloss;
    fixed3 diffAlbedo = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);

    // Add the two together.
    fixed4 c;
    c.rgb = diffAlbedo + transAlbedo + s.Emission;
    c.a = _LightColor0.a * _SpecColor.a * spec * atten;
    return c;
}

#endif