using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEngine.Rendering.PostProcessing;
 
[Serializable]
[PostProcess(typeof(RainOnLensRenderer), PostProcessEvent.BeforeStack, "Anthony/Rain On Lens")]
public sealed class RainOnLens : PostProcessEffectSettings
{
    // [Header(Raindrops)][Space]
    // _RainDropsTex ("Rain Drops Texture", 2D) = "bump" {}
    // _RainDropsScale ("Rain Drops Scale", Float) = 1
    // _RainDropsNormalStrength ("Rain Normal Strength", Float) = 3
    // _RainDropsAnimSpeed ("Rain Drops Animation Speed", Float) = 0.7
    // _RainDropsAmount ("Rain Drops Amount", Float) = 10
    // _RainDropsSmoothnessPower ("Rain Drops Smoothness Power", Float) = 0.1
    
    
    // Rain drops
    public TextureParameter rainDropsTexture = new TextureParameter { value = null };
    public FloatParameter rainDropsScale = new FloatParameter { value = 1f };
    public FloatParameter rainDropsNormalStrength = new FloatParameter { value = 3f};
}
 
public sealed class RainOnLensRenderer : PostProcessEffectRenderer<BloodPostProcess>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/RainOnLens"));
        
        // // Set properties
        // sheet.properties.SetFloat("_LensDistortionTightness", settings.lensDistortionTightness);
        // sheet.properties.SetFloat("_LensDistortionStrength", settings.lensDistortionStrength);
        // if (settings.wetFilterTexture != null)
        // {
        //     sheet.properties.SetTexture("_WetBump", settings.wetFilterTexture);
        // }
        // sheet.properties.SetVector("_WetTileOffset", settings.wetTileOffset);
        // sheet.properties.SetFloat("_WetStrength", settings.wetStrength);
        //
        // sheet.properties.SetVector("_BloodColor", settings.bloodColor);
        // sheet.properties.SetFloat("_BloodOpacity", settings.bloodOpacity);
        // sheet.properties.SetFloat("_BloodStrength", settings.bloodStrength);

        // Render
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
