using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Light))]
public class LightOscillate : MonoBehaviour
{
    #region Properties
    Light light => GetComponent<Light>();

    [Header("Light Settings")] [Space]
    [SerializeField] Vector2 lightIntensityMinMax = new Vector2(1, 2);
    [SerializeField] Vector2 lightRangeMinMax = new Vector2(10, 15);
    [SerializeField] float oscillateDuration = 2f;
    [SerializeField] AnimationCurve oscillateCurve;

    [SerializeField] Renderer affectedObject;
    [SerializeField] string lightParamName;
    
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
    
    #endregion
    
    void Start()
    {
        
    }

    void Update()
    {
        UpdateLight();
    }

    void OnValidate()
    {
        UpdateLight();
    }

    void UpdateLight()
    {
        if (!light)
        {
            return;
        }

        float currentTime = Time.time % oscillateDuration;
        float t = currentTime / oscillateDuration;
        float curveAlpha = oscillateCurve.Evaluate(t);

        float lightIntensity = Mathf.Lerp(lightIntensityMinMax.x, lightIntensityMinMax.y, curveAlpha);
        float lightRange = Mathf.Lerp(lightRangeMinMax.x, lightRangeMinMax.y, curveAlpha);

        light.intensity = lightIntensity;
        light.range = lightRange;
        
        if (affectedObject != null)
        {
            // Retrieve material property block from the renderer
            //  which contains all the default values we set on the material of said renderer
            affectedObject.GetPropertyBlock(Mpb);
            
            // Modify the temporary material property block
            Mpb.SetFloat(lightParamName, curveAlpha);
            
            // Replace material property block in the renderer with our current one
            affectedObject.SetPropertyBlock(Mpb);
        }
    }
}
