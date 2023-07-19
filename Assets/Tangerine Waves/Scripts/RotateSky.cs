using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateSky : MonoBehaviour
{
    public float RotateSpeed = 0.0f;

    public float MaxExposure = 1.6f;
    public float MinExposure = 1.0f;
    public float ExposureDuration = 2.0f;
    float exposureTimer = 0.0f;
    float exposureSign = 1;
    

    void Update()
    {
        //RenderSettings.skybox.SetFloat("_Rotation", Time.time * RotateSpeed);
        
        exposureTimer += Time.deltaTime * Mathf.Sign(exposureSign);
        if (exposureTimer >= ExposureDuration || exposureTimer < 0.0f)
        {
            exposureSign *= -1;
        }

        float Exposure = Mathf.Lerp(MinExposure, MaxExposure, exposureTimer / ExposureDuration);
        RenderSettings.skybox.SetFloat("_Exposure", Exposure);
    }
}
