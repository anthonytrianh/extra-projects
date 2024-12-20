Shader "Anthony/Decal Alpha"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Color ("Color", Color) = (1,1,1,1)
        _Threshold ("Threshold", Range(0, 1)) = 0.01
    }
    CGINCLUDE
    #include "Decals.cginc"
    
    ENDCG
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent-400"
            "Queue"="Transparent+1" 
            "PreviewType"="Plane"
            "DisableBatching" = "True"
        }
        LOD 100
        
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        ZTest GEqual
        Cull Front
        Lighting Off
        Offset -1,-1

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragAlpha
            
            ENDCG
        }
    }
}
