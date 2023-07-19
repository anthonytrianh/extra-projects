using UnityEngine.Rendering.PostProcessing;
using UnityEditor.Rendering.PostProcessing;
#if UNITY_EDITOR
[PostProcessEditor(typeof(Underwater))]
public sealed class UnderwaterEditor : PostProcessEffectEditor<Underwater>
{
    SerializedParameterOverride m_DeepColor;
    SerializedParameterOverride m_ShallowColor;
    SerializedParameterOverride m_MaskTex;
    SerializedParameterOverride m_WaterBackfaceTex;
    SerializedParameterOverride m_WaterlineThickness;

    SerializedParameterOverride m_LensDistortionTightness;
    SerializedParameterOverride m_LensDistortionStrength;
    SerializedParameterOverride m_WetFilterTex;
    SerializedParameterOverride m_WetTileOffset;
    SerializedParameterOverride m_WetStrength;

    SerializedParameterOverride m_FogDensity;
    SerializedParameterOverride m_FogScale;
    SerializedParameterOverride m_SSSOpacity;

    SerializedParameterOverride m_CausticsTex;
    SerializedParameterOverride m_CausticsBrightness;
    SerializedParameterOverride m_CausticsSpeed;
    SerializedParameterOverride m_CausticsTiling;
    SerializedParameterOverride m_UnderwaterCausticsStrength;

    public override void OnEnable()
    {
        m_DeepColor = FindParameterOverride(x => x.deepColor);
        m_ShallowColor = FindParameterOverride(x => x.shallowColor);
        m_MaskTex = FindParameterOverride(x => x.underwaterMaskTexture);
        m_WaterBackfaceTex = FindParameterOverride(x => x.waterBackfaceTexture);
        m_WaterlineThickness = FindParameterOverride(x => x.waterlineThickness);

        m_LensDistortionTightness = FindParameterOverride(x => x.lensDistortionTightness);
        m_LensDistortionStrength = FindParameterOverride(x => x.lensDistortionStrength);
        m_WetFilterTex = FindParameterOverride(x => x.wetFilterTexture);
        m_WetTileOffset = FindParameterOverride(x => x.wetTileOffset);
        m_WetStrength = FindParameterOverride(x => x.wetStrength);

        m_FogDensity = FindParameterOverride(x => x.fogDensity);
        m_FogScale = FindParameterOverride(x => x.fogScale);
        m_SSSOpacity = FindParameterOverride(x => x.subsurfaceScattering);

        m_CausticsTex = FindParameterOverride(x => x.causticsTexture);
        m_CausticsBrightness = FindParameterOverride(x => x.causticsBrightness);
        m_CausticsSpeed = FindParameterOverride(x => x.causticsSpeed);
        m_CausticsTiling = FindParameterOverride(x => x.causticsTiling);
        m_UnderwaterCausticsStrength = FindParameterOverride(x => x.underwaterCausticsStrength);
    }

    public override void OnInspectorGUI()
    {
        EditorUtilities.DrawHeaderLabel("Underwater");
        PropertyField(m_DeepColor);
        PropertyField(m_ShallowColor);
        PropertyField(m_MaskTex);
        PropertyField(m_WaterBackfaceTex);
        PropertyField(m_WaterlineThickness);

        EditorUtilities.DrawHeaderLabel("Snorkel");
        PropertyField(m_LensDistortionTightness);
        PropertyField(m_LensDistortionStrength);
        PropertyField(m_WetFilterTex);
        PropertyField(m_WetTileOffset);
        PropertyField(m_WetStrength);

        EditorUtilities.DrawHeaderLabel("Fog");
        PropertyField(m_FogDensity);
        PropertyField(m_FogScale);
        PropertyField(m_SSSOpacity);

        EditorUtilities.DrawHeaderLabel("Caustics");
        PropertyField(m_CausticsTex);
        PropertyField(m_CausticsBrightness);
        PropertyField(m_CausticsSpeed);
        PropertyField(m_CausticsTiling);
        PropertyField(m_UnderwaterCausticsStrength);


    }
}
#endif