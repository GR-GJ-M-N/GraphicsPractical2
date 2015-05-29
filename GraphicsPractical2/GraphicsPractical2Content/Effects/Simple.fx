//------------------------------------------- Defines -------------------------------------------

#define Pi 3.14159265

//------------------------------------- Top Level Variables -------------------------------------

// Top level variables can and have to be set at runtime

// Matrices for 3D perspective projection 
float4x4 View, Projection, World;

//---------------------------------- Input / Output structures ----------------------------------

// Each member of the struct has to be given a "semantic", to indicate what kind of data should go in
// here and how it should be treated. Read more about the POSITION0 and the many other semantics in 
// the MSDN library

struct VertexShaderInput
{
	float4 Position3D : POSITION0;
	float4 Normal3D : NORMAL0;
	float4 Color : COLOR0;
};

// The output of the vertex shader. After being passed through the interpolator/rasterizer it is also 
// the input of the pixel shader. 
// Note 1: The values that you pass into this struct in the vertex shader are not the same as what 
// you get as input for the pixel shader. A vertex shader has a single vertex as input, the pixel 
// shader has 3 vertices as input, and lets you determine the color of each pixel in the triangle 
// defined by these three vertices. Therefor, all the values in the struct that you get as input for 
// the pixel shaders have been linearly interpolated between there three vertices!
// Note 2: You cannot use the data with the POSITION0 semantic in the pixel shader.

struct VertexShaderOutput
{
	float4 Position2D : POSITION0;
	float4 Color : COLOR0;
};

//------------------------------------------ Functions ------------------------------------------

// Implement the Coloring using normals assignment here
float4 NormalColor(VertexShaderOutput input)
{
	//return float4(input.Normal, 0, 0, 1);	
	//return float4(input.Normal, input.Normal, input.Normal, 1);
	//return float4(input.Position2D, 0, 0, 1);
	//return float4(input.Position2D.x, 0, 0, 1);
	//return float4(input.Position2D[0], 0, 0, 1);
	//return float4(input.Position2D.xyz, 0, 0, 1);
	//return float4(input.Position2D.xyzw, 0, 0, 1);
	//return float4(input.Position2D.xy.x, 0, 0, 1);
	//return float4(input.Position2D.Normal, 0, 0, 1);
	//return float4(input.Position2D, 0, 0, 1);
	//return float4(input.Position2D);
	//return float4(input.Color, 0, 0, 1);
	return float4(input.Color.r, input.Color.g, input.Color.b, 0); //zwart

	//return float4(1, 0, 0, 1); //voorbeeld
}

// Implement the Procedural texturing assignment here
float4 ProceduralColor(/* parameter(s) */)
{
	return float4(0, 0, 0, 1);
}

//---------------------------------------- Technique: Simple ----------------------------------------

VertexShaderOutput SimpleVertexShader(VertexShaderInput input)
{
	// Allocate an empty output struct
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Do the matrix multiplications for perspective projection and the world transform
	float4 worldPosition = mul(input.Position3D, World);
    float4 viewPosition  = mul(worldPosition, View);
	output.Position2D    = mul(viewPosition, Projection);

	return output;
}

float4 SimplePixelShader(VertexShaderOutput input) : COLOR0
{
	float4 color = NormalColor(input);

	return color;
}

technique Simple
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 SimpleVertexShader();
		PixelShader  = compile ps_2_0 SimplePixelShader();
	}
}