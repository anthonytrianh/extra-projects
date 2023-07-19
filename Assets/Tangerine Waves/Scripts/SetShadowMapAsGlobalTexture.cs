using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Light))]
public class SetShadowMapAsGlobalTexture : MonoBehaviour
{
    public string textureSemanticName = "_SunCascadedShadowMap";
#if UNITY_EDITOR
    public bool reset;
#endif

    private RenderTexture shadowMapRenderTexture;
    private CommandBuffer commandBuffer;
    private Light lightComponent;
    
    void OnEnable()
    {
        lightComponent = GetComponent<Light>();
        SetupCommandBuffer();
    }

    void OnDisable()
    {
        lightComponent.RemoveCommandBuffer(LightEvent.AfterShadowMap, commandBuffer);
        ReleaseCommandBuffer();
    }

    private void Start()
    {
        #if !UNITY_EDITOR
                Cursor.visible = false;
        #endif
    }

#if UNITY_EDITOR
    void Update()
    {
        if(reset)
        {
            OnDisable();
            OnEnable();
            reset = false;
        }

        Shader.SetGlobalMatrix("unity_WorldToLight", lightComponent.transform.worldToLocalMatrix);
    }
#endif

    void SetupCommandBuffer()
    {
        commandBuffer = new CommandBuffer();
        
        RenderTargetIdentifier shadowMapRenderTextureIdentifier = BuiltinRenderTextureType.CurrentActive;
        commandBuffer.SetGlobalTexture(textureSemanticName, shadowMapRenderTextureIdentifier);

        lightComponent.AddCommandBuffer(LightEvent.AfterShadowMap, commandBuffer);
    }

    void ReleaseCommandBuffer()
    {
        commandBuffer.Clear();
    }
}