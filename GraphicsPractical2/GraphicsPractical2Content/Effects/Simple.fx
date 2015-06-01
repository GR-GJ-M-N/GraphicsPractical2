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

//input for the vertex shader
struct VertexShaderInput
{
	float4 Position3D : POSITION0;
	float4 Normal3D : NORMAL0;
	float4 Color : COLOR0;
	float4 Place : TEXCOORD0;
};

// The output of the vertex shader. After being passed through the interpolator/rasterizer it is also 
// the input of the pixel shader. 
// Note 1: The values that you pass into this struct in the vertex shader are not the same as what 
// you get as input for the pixel shader. A vertex shader has a single vertex as input, the pixel 
// shader has 3 vertices as input, and lets you determine the color of each pixel in the triangle 
// defined by these three vertices. Therefor, all the values in the struct that you get as input for 
// the pixel shaders have been linearly interpolated between there three vertices!
// Note 2: You cannot use the data with the POSITION0 semantic in the pixel shader.

// output of the vertex shader
struct VertexShaderOutput
{
	float4 Position2D : POSITION0;
	float4 Color : COLOR0;
	float3 Normal : TEXCOORD1;
	float3 Place : TEXCOORD0;
	//float4 Place : TEXCOORD0;
};

//------------------------------------------ Functions ------------------------------------------

// Implement the Coloring using normals assignment here
float4 NormalColor(VertexShaderOutput input)
{
	// the normals are used to determine the color
	return float4(input.Normal.x, input.Normal.y, input.Normal.z, 1);
}

// Implement the Procedural texturing assignment here
float4 ProceduralColor(VertexShaderOutput input)
{
	// the negative normals are used to determine the color
	return float4(-input.Normal.x, -input.Normal.y, -input.Normal.z, 1);
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

	// values are passed on into a form which te vertex shader can output
	output.Normal = input.Normal3D.xyz;
	output.Place = input.Position3D.xyz;

	return output;
}

// this variable controles the size of the checkers
int checkerSize = 8;

//this function returns whether a given point is a black or a white(normal color) pixel
bool Checker(VertexShaderOutput input)
{
	bool x = (int)((input.Place.x + 3) * checkerSize) % 2;
	bool y = (int)((input.Place.y + 3) * checkerSize) % 2;

	//the checkerboard pattern is made
	if (x == y)
		return true;
	else
		return false;
}	

float4 SimplePixelShader(VertexShaderOutput input) : COLOR0
{
	//use normals to do the coloring
	if(Checker(input))
	{
		return NormalColor(input);
	}
	//use negative normals to do the coloring
	else
	{
		return ProceduralColor(input);
	}
}

technique Simple
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 SimpleVertexShader();
		PixelShader  = compile ps_2_0 SimplePixelShader();
	}
}