using UnityEditor.Rendering.PostProcessing;
#if UNITY_EDITOR
[PostProcessEditor(typeof(BloodPostProcess))]
public sealed class BloodPostProcessEditor : PostProcessEffectEditor<BloodPostProcess>
{
    SerializedParameterOverride m_LensDistortionTightness;
    SerializedParameterOverride m_LensDistortionStrength;

    SerializedParameterOverride m_WetFilterTex;
    SerializedParameterOverride m_WetTileOffset;
    SerializedParameterOverride m_WetStrength;

    SerializedParameterOverride m_BloodColor;
    SerializedParameterOverride m_BloodOpacity;
    SerializedParameterOverride m_BloodStrength;

    public override void OnEnable()
    {
      
        m_LensDistortionTightness = FindParameterOverride(x => x.lensDistortionTightness);
        m_LensDistortionStrength = FindParameterOverride(x => x.lensDistortionStrength);
        m_WetFilterTex = FindParameterOverride(x => x.wetFilterTexture);
        m_WetTileOffset = FindParameterOverride(x => x.wetTileOffset);
        m_WetStrength = FindParameterOverride(x => x.wetStrength);

        m_BloodColor = FindParameterOverride(x => x.bloodColor);
        m_BloodOpacity = FindParameterOverride(X => X.bloodOpacity);
        m_BloodStrength = FindParameterOverride(X => X.bloodStrength);
     
    }

    public override void OnInspectorGUI()
    {
        EditorUtilities.DrawHeaderLabel("Snorkel");
        PropertyField(m_LensDistortionTightness);
        PropertyField(m_LensDistortionStrength);

        EditorUtilities.DrawHeaderLabel("Wet");
        PropertyField(m_WetFilterTex);
        PropertyField(m_WetTileOffset);
        PropertyField(m_WetStrength);

        EditorUtilities.DrawHeaderLabel("Blood");
        PropertyField(m_BloodColor);
        PropertyField(m_BloodOpacity);
        PropertyField(m_BloodStrength);
    }
}
#endif