using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class ImageEffectSimple : MonoBehaviour
{
    Shader shader;
    public Material Material;

    void Awake()
    {
        if (Material == null)
        {
            shader = Shader.Find("Hidden/RainOnLensImageEffect");
            Material = new Material(shader);
        }
    }

    protected void OnRenderImage(RenderTexture Source, RenderTexture Destination)
    {
        //Debug.Log("Rendering Simple");

        if (Material == null)
        {
            Graphics.Blit(Source, Destination);
            return;
        }

        Graphics.Blit(Source, Destination, Material);
    }
}
