using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;
 
[Serializable]
[PostProcess(typeof(UnderwaterRenderer), PostProcessEvent.BeforeStack, "Anthony/Experimental/Underwater")]
public sealed class Underwater : PostProcessEffectSettings
{
    // Underwater
    public ColorParameter deepColor = new ColorParameter { value = Color.blue };
    public ColorParameter shallowColor = new ColorParameter { value = Color.green };
    public TextureParameter underwaterMaskTexture = new TextureParameter { value = null };
    public TextureParameter waterBackfaceTexture = new TextureParameter { value = null };
    [Range(0f, 0.1f)]
    public FloatParameter waterlineThickness = new FloatParameter { value = 0.0269f };


    // Snorkel
    public FloatParameter lensDistortionTightness = new FloatParameter {value = 9.3f};
    public FloatParameter lensDistortionStrength = new FloatParameter {value = -0.21f};
    public TextureParameter wetFilterTexture = new TextureParameter { value = null };
    public Vector4Parameter wetTileOffset = new Vector4Parameter { value = new Vector4(1, 0.5625f, 0.39f, -0.15f) };
    public FloatParameter wetStrength = new FloatParameter { value = 0.08f };

    // Depth Fog
    public FloatParameter fogDensity = new FloatParameter { value = 4.8f };
    public FloatParameter fogScale = new FloatParameter { value = 0.59f };
    [Range(0f, 1f)]
    public FloatParameter subsurfaceScattering = new FloatParameter { value = 0.94f};

    // Caustics
    public TextureParameter causticsTexture =  new TextureParameter { value = null };
    public FloatParameter causticsBrightness = new FloatParameter { value = 4f };
    public FloatParameter causticsSpeed = new FloatParameter { value = 0.15f };
    public FloatParameter causticsTiling = new FloatParameter { value = 0.25f };
    public FloatParameter underwaterCausticsStrength = new FloatParameter { value = 0.76f };

}
 
public sealed class UnderwaterRenderer : PostProcessEffectRenderer<Underwater>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/UnderwaterPostProcessVersion"));
        
        // Set properties
        sheet.properties.SetColor("_DeepColor", settings.deepColor);
        sheet.properties.SetColor("_ShallowColor", settings.shallowColor);
        if (settings.underwaterMaskTexture != null)
        {
            sheet.properties.SetTexture("_MaskTex", settings.underwaterMaskTexture);
        }
        sheet.properties.SetFloat("_WaterlineThickness", settings.waterlineThickness);

        sheet.properties.SetFloat("_LensDistortionTightness", settings.lensDistortionTightness);
        sheet.properties.SetFloat("_LensDistortionStrength", settings.lensDistortionStrength);
        if (settings.wetFilterTexture != null)
        {
            sheet.properties.SetTexture("_WetBump", settings.wetFilterTexture);
        }
        sheet.properties.SetVector("_WetTileOffset", settings.wetTileOffset);
        sheet.properties.SetFloat("_WetStrength", settings.wetStrength);

        sheet.properties.SetFloat("_FogDensity", settings.fogDensity);
        sheet.properties.SetFloat("_FogScale", settings.fogScale);
        sheet.properties.SetFloat("_SSSOpacity", settings.subsurfaceScattering);
        if (settings.waterBackfaceTexture != null)
        {
            sheet.properties.SetTexture("_WaterBackfaceTex", settings.waterBackfaceTexture);
        }

        if (settings.causticsTexture != null)
        {
            sheet.properties.SetTexture("_CausticsTex", settings.causticsTexture);
        }
        sheet.properties.SetFloat("_CausticsBrightness", settings.causticsBrightness);
        sheet.properties.SetFloat("_CausticsSpeed", settings.causticsSpeed);
        sheet.properties.SetFloat("_CausticsTiling", settings.causticsTiling);
        sheet.properties.SetFloat("_UnderwaterCausticsStrength", settings.underwaterCausticsStrength);



        // Render
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
