float2x2 RM2D(float a)
{
    return float2x2(cos(a), sin(a), -sin(a), cos(a));
}

float GetAnimatedOrganicFractal(
    float scale = 6, float scaleMultStep = 1.2,
    float rotationStep = 5, int iterations = 16,
    float2 uv = float2(0, 0), float uvAnimationSpeed = 3.5,
    float rippleStrength = 0.9, float rippleMaxFrequency = 1.4, float rippleSpeed = 5,
    float brightness = 2
)
{
    // Remap to [-1.0, 1.0]
    uv = float2(uv - 0.5) * 2.0;
    
    float2 n, q;
    float invertedRadialGradient = pow(length(uv), 2.0);
    
    float output = 0.0;
    float2x2 rotationMatrix = RM2D(rotationStep);
    
    float t = _Time.y;
    float uvTime = t * uvAnimationSpeed;
    
    // Ripples can be pre-calculated and passed from outside
    float ripples = sin((t * rippleSpeed) - (invertedRadialGradient * rippleMaxFrequency)) * rippleStrength;
    
    for (int i = 0; i < iterations; i++)
    {
        uv = mul(rotationMatrix, uv);
        n = mul(rotationMatrix, n);
        
        float2 animatedUV = (uv * scale) + uvTime;
        
        q = animatedUV + ripples + i + n;
        output += dot(cos(q) / scale, float2(1.0, 1.0) * brightness);
        
        n -= sin(q);
        
        scale *= scaleMultStep;
    }
    
    return output;

}

#define PI UNITY_PI
#define TAU 6.283185307179586
#define Deg2Rad (UNITY_PI * 2) / 360.0
#define Rad2Deg 360 / (UNITY_PI * 2)

// Rotation
float2 rotate(float2 v, float angRad)
{
    float ca = cos(angRad);
    float sa = sin(angRad);

    return float2(ca * v.x - sa * v.y, sa * v.x + ca * v.y);
}

// Hex
inline float hexagonSDF(float2 p, float radius, float angleOffset = 0)
{
	// The point that is perpendicular to one of the diagonal
	//  sides of the hex
	/** use 1/2 this point for hexagon, and 1 for rhombus/diamond **/
    float2 diagonalPerpendicular = rotate(float2(1, sqrt(3)), angleOffset * Deg2Rad);
	// Put point into quadrant I (effectively mirroring all four quadrants)
    p = abs(p);
	// The point is inside the hex if the projection of the point
	//  onto half the diagonalPerpendicular is less than or equal to radius
	//  and that the x coord is less than radius
	// We essentially check if the point is within one of the 4
	// the right trapezoid that make up the hexagon
    float isInsideHex = max(dot(diagonalPerpendicular * 0.5, p), p.x) - radius;
    return isInsideHex;
}

void HexSdfMask(float2 uv, float radius, int waveCount, out float outSDF, out float mask)
{
    uv = uv * 2 - 1;
    float sdf = hexagonSDF(uv, radius);
    sdf = frac(sdf * waveCount);
    
    outSDF = 1 - sdf;
    mask = 1 - smoothstep(1.1, 0.95, sdf);
}