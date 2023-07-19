#ifndef	ANTHONY_SHADER_MATHS
#define ANTHONY_SHADER_MATHS

#define PI UNITY_PI
#define TAU 6.283185307179586
#define Deg2Rad (UNITY_PI * 2) / 360.0
#define Rad2Deg 360 / (UNITY_PI * 2)

// Inverse lerp
float ilerp(float a, float b, float v) 
{
	return (v - a) / (b - a);
}

// Remap
float remap(float iMin, float iMax, float oMin, float oMax, float v) 
{
	float t = ilerp(iMin, iMax, v);
	return lerp(oMin, oMax, t);
}

// Spherical (Normal) Lerp
float3 slerp(float3 a, float3 b, float t)
{
	return normalize(lerp(a, b, t));
}

// Fresnel
float fresnel(float3 viewDir, float3 normal, float exp) 
{
	float3 V = viewDir;
	float3 N = normal;

	return pow(1 - saturate(dot(V, N)), exp);
}

// Determinant
float det(float2 a, float2 b) 
{
	return a.x * b.y - a.y * b.x;
}

// Direction to angle
float DirToAngRad(float2 v) 
{
	return atan2(v.y, v.x);
}

// Direction to Rectilinear
float2 DirToRectilinear(float3 dir) 
{
	float x = atan2(dir.z, dir.x);
	x = x / TAU + 0.5;
	float y = dir.y * 0.5 + 0.5;
	return float2(x, y);
}

// Rotation
float2 rotate(float2 v, float angRad) 
{
	float ca = cos(angRad);
	float sa = sin(angRad);

	return float2(ca * v.x - sa * v.y, sa * v.x + ca * v.y);
}

// Rotate uvs (angRad == _Time.y * Speed)
void rotateUVs(inout float2 uv, float angRad) 
{
	uv -= 0.5;
	float sinX = sin(angRad);
	float cosX = cos(angRad);
	float sinY = sin(angRad);
	float2x2 rotationMatrix = float2x2(cosX, -sinX, sinY, cosX);
	rotationMatrix *= 0.5;
	rotationMatrix += 0.5;
	rotationMatrix = rotationMatrix * 2 - 1;
	uv = mul(uv, rotationMatrix);
	uv += 0.5;
}

// Twirl
float2 twirl2D(float2 UV, float2 Center, float Strength, float2 Offset)
{
	float2 delta = UV - Center;
	float angle = Strength * length(delta);
	float x = cos(angle) * delta.x - sin(angle) * delta.y;
	float y = sin(angle) * delta.x + cos(angle) * delta.y;
	return float2(x + Center.x + Offset.x, y + Center.y + Offset.y);
}

// Wave
float Wave(float p, float speed, float waveCount)
{
	return cos((p - _Time.y * speed) * TAU * waveCount);
}

float Neg11To01(float value)
{
    return value * 0.5 + 0.5;
}

///////////////////////////////////////////////////////
// Random functions

float rand2(in float2 st)
{
    return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
}

// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
float rand3(float3 co)
{
    return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}


//////////////////////////////////////////////////////
// Rotation functions

 // Construct a rotation matrix that rotates around the provided axis, sourced from:
// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
float3x3 AngleAxis3x3(float angle, float3 axis)
{
    float c, s;
    sincos(angle, s, c);

    float t = 1 - c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;

    return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
}


/////////////////////////////////////////////////////
// SDF Functions
// Some functions sourced from https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm

// Circle
inline float circleSDF(float2 p, float radius) 
{
	return length(p) - radius;
}

// Square
inline float squareSDF(float2 p, float side) 
{
	p = abs(p);
	return max(p.x, p.y) - side;
}

// Triangle - Equilateral
//	2	1
//	  3
inline float triEquilateralSDF(float2 p, float r) 
{
	const float side = sqrt(3);
	// Mirrors around the vertical axis (1 <--- 0 ---> 1)
	//	creating horizontal symmetry
	p.x = abs(p.x) - r;
	// Offsets the y downward so that the vertical axis fully contains the
	//	height of the equilateral triangle (1 at the top)
	//	bringing the triangle fully into view
	// This is now a full rectangle taking size of (1 x equiHeight)
	p.y = p.y + r / side;
	// Cut half (triangles) of both rectangles on each side to create
	//	2 right triangles with sides of length equiSide, creating the
	//	equilateral triangle
	if (p.x + p.y * side > 0) {
		p = float2(
			p.x - side * p.y,	
			-side * p.x - p.y)  
			* 0.5;
	}
	// Negate the x value to bring it back to > 0, any pixel that make up
	//	the triangle will have y > 0
	p.x -= clamp(p.x, -2 * r, 0);
	// Now the spaces that is occupied by the triangle will be stored in the
	//	sign of p.y ( < 0 means vacant, > 0 means triangle)
	//	Multiply the length by sign(p.y) to get the triangle shape
	//	Negate length to invert the colors, resulting in sdf where inside
	//	the triangle is < 0, and outside is > 0
	return -length(p) * sign(p.y);

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

// Stroke
// To get a stroke, or a line, with a certain width we need to find the line that is
// perpendicular to the direction that the shape is growing in (<--- width) and then
// we draw two shapes, one large and one small, and get the difference between them to
// get our line.
// ------------------------------- A
// ///////////////////////////////		A - B
// ------------------------------- B
//
//
// ------------------------------- A, B
float strokeSDF(float coord, float cutoff, float width)
{
    float largeRectangle = step(cutoff, coord + width * 0.5);
    float smallRectangle = step(cutoff, coord - width * 0.5);
	float distance = largeRectangle - smallRectangle;
	return saturate(distance);
}

// Fill
// Fill the specified area with black
float fillSDF(float percentage, float size)
{
	return 1.0 - step(percentage, size);
}

// Rectangle
float rectSDF(float2 uv, float2 size)
{
	// Expands uv from (0, 1) to (-1, 1)
	uv = uv * 2 - 1;
	// To achieve a rectangle we simply
	// divide x by the width
	// and    y by the height
	// to find out how much each axis is filled up by
	// the width and height of the shape
	// abs() to mirror the shape across the x and y axes
	// and max() to get the largest bound
	//            width
	// 0 |///////////     | 1
	return max(abs(uv.x / size.x),
		abs(uv.y / size.y));
}

// This version creates the diagonal split pattern
// |||| .
// |||  .
// ||   .
// |    .
// ||   .
// |||  .
// |||| .
float diagonalSplitSDF(float2 uv, float2 size)
{
	uv = uv * 2 - 1;
	float rect = max(abs(uv.x / size.x),
		abs(uv.y / size.y));

	rect = step((uv.x + uv.y), rect) * step((uv.x - uv.y), rect);

	return rect;
}

// Cross
float crossSDF(float2 uv, float2 aspect) 
{
	// (width, height) of each rectangle making up the cross
	float2 size = aspect; // (0.25, x)

	float horizontalRect = rectSDF(uv, size.xy);
	float verticalRect = rectSDF(uv, size.yx);

	return min(horizontalRect, verticalRect);
}

// Star
float starSDF(float2 uv, int vertices, float externalAngle) 
{
	// Remap (0,1) to (-2,2)
	uv = uv * 4 - 2;

	// Find the angle for the current point
	float angle = atan2(uv.y, uv.x) / TAU;
	float segment = angle * float(vertices);

	float singleSegment = (floor(segment) + 0.5) / float(vertices);
	float segmentDivisions = step(0.5, frac(segment));
	float shapeMask = lerp(externalAngle, -externalAngle, segmentDivisions);

	angle = 
		((floor(segment) + 0.5) / float(vertices)
		+ lerp(externalAngle, -externalAngle, step(0.5, frac(segment))))
		* TAU;

	// Mirror the distance on both axes
	return abs(dot(float2(cos(angle),sin(angle)), uv));
}

// signed distance to a n-star polygon with external angle en
float NStarSDF(float2 p, float len, int n, float m) // m=[2,n]
{
	p = p * 4.2 - 2.1;

	// these 4 lines can be precomputed for a given shape
	float an = PI / float(n);
	float en = PI / m;
	float2 acs = float2(cos(an), sin(an));
	float2 ecs = float2(cos(en), sin(en)); // ecs=vec2(0,1) and simplify, for regular polygon,

	// reduce to first sector
	float bn = fmod(atan2(p.x, p.y) + PI, 2.0 * an) - an;
	p = length(p) * float2(cos(bn), abs(sin(bn)));

	// line sdf
	p -= len * acs;
	p += ecs * clamp(-dot(p, ecs), 0.0, len * acs.y / ecs.y);
	return length(p) * sign(p.x);
}

// rays
float raysSDF(float2 uv, int n) 
{
	// Centers uv
	uv -= 0.5;
	return frac(atan2(uv.y, uv.x) / TAU * float(n));
}


#endif //ANTHONY_SHADER_MATHS