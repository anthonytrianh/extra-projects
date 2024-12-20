using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class CandleLightController : MonoBehaviour
{
    private MaterialPropertyBlock mpb;
    public MaterialPropertyBlock Mpb
    {
        get
        {
            if (mpb == null)
                mpb = new MaterialPropertyBlock();
            return mpb;
        }
    }

    Renderer renderer => GetComponent<Renderer>();

    [SerializeField] [ColorUsage(true, true)] Color colorIn = Color.green;
    [SerializeField] [ColorUsage(true, true)] Color colorOut = Color.yellow;
    [SerializeField] float colorContrast = 0.88f;
    [SerializeField] float timeOffset = 0;
    
    void Start()
    {
        SetLightMaterialParams();
    }

    void OnValidate()
    {
        SetLightMaterialParams();
    }
    
    void SetLightMaterialParams()
    {
        renderer.GetPropertyBlock(Mpb);

        Mpb.SetColor("_ColorIn", colorIn);
        Mpb.SetColor("_ColorOut", colorOut);
        Mpb.SetFloat("_ColorGradientContrast", colorContrast);
        Mpb.SetFloat("_TimeOffset", timeOffset);
        
        renderer.SetPropertyBlock(Mpb);
    }
}
