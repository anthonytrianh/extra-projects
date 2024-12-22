using UnityEditor.Rendering.PostProcessing;
#if UNITY_EDITOR
[PostProcessEditor(typeof(BloodPostProcess))]
public sealed class RainOnLensEditor : PostProcessEffectEditor<RainOnLens>
{
    SerializedParameterOverride m_RainDropsTex;
    SerializedParameterOverride m_WetTileOffset;
    SerializedParameterOverride m_WetStrength;

    SerializedParameterOverride m_BloodColor;
    SerializedParameterOverride m_BloodOpacity;
    SerializedParameterOverride m_BloodStrength;

    public override void OnEnable()
    {
        m_WetTileOffset = FindParameterOverride(x => x.rainDropsTexture);
        // m_WetTileOffset = FindParameterOverride(x => x.wetTileOffset);
        // m_WetStrength = FindParameterOverride(x => x.wetStrength);
        //
        // m_BloodColor = FindParameterOverride(x => x.bloodColor);
        // m_BloodOpacity = FindParameterOverride(X => X.bloodOpacity);
        // m_BloodStrength = FindParameterOverride(X => X.bloodStrength);
     
    }

    public override void OnInspectorGUI()
    {
        EditorUtilities.DrawHeaderLabel("Rain Drops");
        PropertyField(m_WetTileOffset);
        // PropertyField(m_WetTileOffset);
        // PropertyField(m_WetStrength);
    }
}
#endif