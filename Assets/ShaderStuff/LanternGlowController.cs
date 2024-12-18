using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class LanternGlowController : MonoBehaviour
{
    [SerializeField]
    private MeshRenderer glassRenderer;
    private Material material;

    [SerializeField]
    [ColorUsage(true, true)]
    private Color color;

    private MaterialPropertyBlock mpb;
    public MaterialPropertyBlock Mpb
    {
        get
        {
            if (mpb == null)
            {
                mpb = new MaterialPropertyBlock();
            }
            return mpb;
        }
    }

    [ExecuteInEditMode]
    void OnValidate()
    {
        if (glassRenderer != null)
        {
            // Retrieve material property block from the renderer
            //  which contains all the default values we set on the material of said renderer
            glassRenderer.GetPropertyBlock(Mpb);
            
            // Modify the temporary material property block
            Mpb.SetColor("_Color", color);
            
            // Replace material property block in the renderer with our current one
            glassRenderer.SetPropertyBlock(Mpb);
        }
    }
}
