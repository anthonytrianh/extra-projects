#ifndef	RGB_SHADER_FUNCS
#define RGB_SHADER_FUNCS
// Outline function
inline fixed4 Outline(float4 input_color, sampler2D input_sampler, float4 input_texelSize, float2 input_texcoord, float4 outlineColor)
{
    if (input_color.a != 0)
    {
        fixed2 width = input_texelSize.xy;

		// Get the neighbouring four pixels.
        fixed4 pixelUp = tex2D(input_sampler, input_texcoord.xy + float2(0, width.y));
        fixed4 pixelDown = tex2D(input_sampler, input_texcoord.xy - float2(0, width.y));
        fixed4 pixelRight = tex2D(input_sampler, input_texcoord.xy + float2(width.x, 0));
        fixed4 pixelLeft = tex2D(input_sampler, input_texcoord.xy - float2(width.x, 0));

		// If one of the neighbouring pixels is invisible, render as outline.
        if (pixelUp.a * pixelDown.a * pixelRight.a * pixelLeft.a == 0)
        {
            return fixed4(1, 1, 1, 1) * outlineColor;
        }
    }
    return (1, 1, 1, 0) * outlineColor;
}

#endif //RGB_SHADER_FUNCS