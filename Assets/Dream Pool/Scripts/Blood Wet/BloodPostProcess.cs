using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEngine.Rendering.PostProcessing;
 
[Serializable]
[PostProcess(typeof(BloodPostProcessRenderer), PostProcessEvent.BeforeStack, "Anthony/Experimental/BloodWet")]
public sealed class BloodPostProcess : PostProcessEffectSettings
{
    // Snorkel
    public FloatParameter lensDistortionTightness = new FloatParameter {value = 9.3f};
    public FloatParameter lensDistortionStrength = new FloatParameter {value = -0.21f};

    // Wet
    public TextureParameter wetFilterTexture = new TextureParameter { value = null };
    public Vector4Parameter wetTileOffset = new Vector4Parameter { value = new Vector4(1, 0.5625f, 0.39f, -0.15f) };
    public FloatParameter wetStrength = new FloatParameter { value = 0.08f };

    // Blood
    [ColorUsageAttribute(true,true)]
    public ColorParameter bloodColor = new ColorParameter { value = new Color(1, 0, 0, 1)};
    public FloatParameter bloodOpacity = new FloatParameter { value = 0f };
    public FloatParameter bloodStrength = new FloatParameter { value = 1f};
}
 
public sealed class BloodPostProcessRenderer : PostProcessEffectRenderer<BloodPostProcess>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/BloodWetPostProcess"));
        
        // Set properties
        sheet.properties.SetFloat("_LensDistortionTightness", settings.lensDistortionTightness);
        sheet.properties.SetFloat("_LensDistortionStrength", settings.lensDistortionStrength);
        if (settings.wetFilterTexture != null)
        {
            sheet.properties.SetTexture("_WetBump", settings.wetFilterTexture);
        }
        sheet.properties.SetVector("_WetTileOffset", settings.wetTileOffset);
        sheet.properties.SetFloat("_WetStrength", settings.wetStrength);

        sheet.properties.SetVector("_BloodColor", settings.bloodColor);
        sheet.properties.SetFloat("_BloodOpacity", settings.bloodOpacity);
        sheet.properties.SetFloat("_BloodStrength", settings.bloodStrength);

        // Render
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
