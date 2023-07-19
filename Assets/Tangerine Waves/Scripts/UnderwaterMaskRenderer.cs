using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class UnderwaterMaskRenderer : MonoBehaviour
{
    public RenderTexture RenderTexture;
    public RenderTexture WaterRT;

    public Material UnderwaterMaskMat;
    public Transform WaterLevel;

    Camera Camera;

    // Start is called before the first frame update
    void Start()
    {
        Camera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        #region Obsolete
        //// Camera plane points
        //var camera = GetComponent<Camera>();

        //Vector3[] points = new Vector3[4];
        //Vector3[] frustumCorners = new Vector3[4];

        //camera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), camera.nearClipPlane, Camera.MonoOrStereoscopicEye.Mono, frustumCorners);
        //for (int i = 0; i < 4; i++)
        //{
        //    var worldSpaceCorner = camera.transform.TransformVector(frustumCorners[i]);
        //    points[i] = camera.transform.TransformVector(frustumCorners[i]);
        //    Debug.DrawRay(camera.transform.position, worldSpaceCorner, Color.blue);
        //}

        //Vector3 NearPlaneCenter = camera.transform.position + camera.transform.forward * camera.nearClipPlane * 2.0f;


        //// Set target active RT
        //RenderTexture.active = RenderTexture;

        //// Read pixels into temporary texture
        //Texture.ReadPixels(new Rect(0, 0, RenderTexture.width, RenderTexture.height), 0, 0);

        //int HalfWidth = RenderTexture.width / 2;
        //int HalfHeight = RenderTexture.height / 2;

        //for (int i = 0; i < RenderTexture.width; i++)
        //{
        //    for (int j = 0; j < RenderTexture.height; j++)
        //    {
        //        float rightPercent = i / (float)RenderTexture.width;
        //        float upPercent = j / (float)RenderTexture.height;

        //        Vector3 CurrentPoint = NearPlaneCenter + camera.transform.right * rightPercent * camera.fieldOfView 


        //        Texture.SetPixel(i, j, Color.black);

        //        if (i == RenderTexture.width / 2 && j == RenderTexture.height / 2)
        //        {
        //            float delta = Mathf.Clamp01(GerstnerWavesInstance.GetWavePosition(TestPoint.position).y - TestPoint.position.y);
        //             Texture.SetPixel(i, j, new Color(delta, delta, delta));
        //                 //TestPoint.position.y < GerstnerWavesInstance.GetWavePosition(TestPoint.position).y ? Color.white : Color.black);
        //        }

        //    }
        //}

        //Texture.Apply();
        //;

        //Debug.Log("Wave pos: " + GerstnerWavesInstance.GetWavePosition(TestPoint.position).ToString());

        //RenderTexture.active = null;
        #endregion

        Camera.targetTexture = RenderTexture;
        Camera.Render();

        DrawQuad();

        // Set shader vars
        Shader.SetGlobalMatrix("Ocean_InverseViewMatrix", Camera.cameraToWorldMatrix);
        Shader.SetGlobalMatrix("Ocean_InverseProjectionMatrix" ,GL.GetGPUProjectionMatrix(Camera.projectionMatrix, false).inverse);

        if (WaterLevel != null)
            Shader.SetGlobalFloat("WaterLevel", WaterLevel.position.y);
    }

    void DrawQuad()
    {
        GL.PushMatrix();

        GL.LoadOrtho();

        GL.Begin(GL.QUADS);

        GL.TexCoord2(1.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 0.0f);
        GL.TexCoord2(1.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);
        GL.TexCoord2(0.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 0.0f);
        GL.TexCoord2(0.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 0.0f);

        GL.End();

        GL.PopMatrix();
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (UnderwaterMaskMat == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        Graphics.Blit(source, destination, UnderwaterMaskMat, 0);
    }

    //public GerstnerWaves GerstnerWavesInstance;
}