using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class UnderwaterImgEffect : MonoBehaviour
{
    public RenderTexture RenderTexture;
    Camera Camera;

    public Material UnderwaterMat;

    // Shadows
    static Matrix4x4 textureScaleAndBias;
    Matrix4x4 shadowMatrix;

    void Start()
    {
        Camera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        //// Shadows
        //// Setup texture scale and bias matrix
        //textureScaleAndBias = Matrix4x4.identity;
        //textureScaleAndBias.m00 = 0.5f;
        //textureScaleAndBias.m11 = 0.5f;
        //textureScaleAndBias.m22 = 0.5f;
        //textureScaleAndBias.m03 = 0.5f;
        //textureScaleAndBias.m13 = 0.5f;
        //textureScaleAndBias.m23 = 0.5f;

        //ComputeShadowTransform(Camera.projectionMatrix, Camera.worldToCameraMatrix);
    }

    void ComputeShadowTransform(Matrix4x4 proj, Matrix4x4 view) 
    {
        // Currently CullResults ComputeDirectionalShadowMatricesAndCullingPrimitives doesn't
        // apply z reversal to projection matrix. We need to do it manually here.
        if (SystemInfo.usesReversedZBuffer) {
            proj.m20 = -proj.m20;
            proj.m21 = -proj.m21;
            proj.m22 = -proj.m22;
            proj.m23 = -proj.m23;
        }

        Matrix4x4 worldToShadow = proj * view;

        // Apply texture scale and offset to save a MAD in shader.
        shadowMatrix = textureScaleAndBias * worldToShadow;

        Shader.SetGlobalMatrix("_ShadowMatrix", shadowMatrix);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (UnderwaterMat == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        //UnderwaterMat.SetTexture("MaskTexture", RenderTexture);
        Graphics.Blit(source, destination, UnderwaterMat);
    }
}
