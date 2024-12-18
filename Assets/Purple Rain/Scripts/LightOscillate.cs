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
    }
}
