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

    [SerializeField] float timeOffset = 0;
    
    void Start()
    {
        SetTimeOffset();
    }

    void OnValidate()
    {
        SetTimeOffset();
    }
    
    void SetTimeOffset()
    {
        renderer.GetPropertyBlock(Mpb);

        Mpb.SetFloat("_TimeOffset", timeOffset);
        
        renderer.SetPropertyBlock(Mpb);
    }
}
