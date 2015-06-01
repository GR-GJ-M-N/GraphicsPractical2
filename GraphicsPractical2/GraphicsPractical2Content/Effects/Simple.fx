//------------------------------------------- Defines -------------------------------------------

#define Pi 3.14159265

//------------------------------------- Top Level Variables -------------------------------------

// Top level variables can and have to be set at runtime

// Matrices for 3D perspective projection 
float4x4 View, Projection, World;
float4 DiffuseColor, AmbientColor, SpecularColor;
float3 Light, Camera;
float AmbientIntensity, SpecularIntensity, SpecularPower;

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
	float3 Normal : TEXCOORD0;
	float3 WorldPosition : TEXCOORD1;
};

//------------------------------------------ Functions ------------------------------------------

// Implement the Coloring using normals assignment here
float4 NormalColor(VertexShaderOutput input)
{
	return float4(input.Normal.x, input.Normal.y, input.Normal.z, 1);
}

// Implement the Procedural texturing assignment here
float4 ProceduralColor(VertexShaderOutput input)
{
	return float4((input.Normal.x % 0.2) * 10, (input.Normal.y % 0.2) * 10, 0, 1);
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

	output.Normal = input.Normal3D.xyz;

	return output;
}

float4 SimplePixelShader(VertexShaderOutput input) : COLOR0
{
	//float4 color = NormalColor(input);
	float4 color = ProceduralColor(input);

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

//---------------------------------------- Technique: 2.1 Lambertian ----------------------------------------

VertexShaderOutput LambertianVertexShader(VertexShaderInput input)
{
	// Allocate an empty output struct
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Do the matrix multiplications for perspective projection and the world transform
	float4 worldPosition = mul(input.Position3D, World);
    float4 viewPosition  = mul(worldPosition, View);
	output.Position2D    = mul(viewPosition, Projection);

	// Interpolate the 3D position
	output.WorldPosition = mul(output.Position2D, World);

	output.Normal = input.Normal3D.xyz;	

	return output;
}

float4 LambertianPixelShader(VertexShaderOutput input) : COLOR0
{
	float3x3 rotationAndScale = (float3x3) World;
	float3 normal = input.Normal;
	normal = mul(normal, rotationAndScale);
	float3 tLight = mul(Light, rotationAndScale);

	//Normalize the normal
	normal = normalize(normal);

	//Calculate L
	float3 lVector = normalize(tLight - normal);

	//Calculate n dot l, clamp to 0, 1
	float intensity = saturate(dot(normal, lVector));

	return AmbientIntensity * AmbientColor + intensity * DiffuseColor;

}

technique Lambertian
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 LambertianVertexShader();
		PixelShader  = compile ps_2_0 LambertianPixelShader();
	}
}

//---------------------------------------- Technique: 2.3 Blinn-Phong ----------------------------------------

VertexShaderOutput BlinnPhongVertexShader(VertexShaderInput input)
{
	// Allocate an empty output struct
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Do the matrix multiplications for perspective projection and the world transform
	float4 worldPosition = mul(input.Position3D, World);
    float4 viewPosition  = mul(worldPosition, View);
	output.Position2D    = mul(viewPosition, Projection);

	// Interpolate the 3D position
	output.WorldPosition = mul(output.Position2D, World);

	output.Normal = input.Normal3D.xyz;	

	return output;
}

float4 BlinnPhongPixelShader(VertexShaderOutput input) : COLOR0
{
	float3x3 rotationAndScale = (float3x3) World;
	float3 normal = input.Normal;
	normal = mul(normal, rotationAndScale);
	float3 tLight = mul(Light, rotationAndScale);

	//Normalize the normal
	normal = normalize(normal);

	//Calculate L
	float3 lVector = normalize(tLight - normal);

	//Calculate v (the vector to the camera)
	float3 vVector = normalize(Camera - normal);

	float3 hVector = (vVector + lVector) / length(vVector + lVector);

	//Calculate n dot l, clamp to 0, 1
	float intensity = saturate(dot(normal, lVector));
	float spec = SpecularColor * SpecularIntensity * pow(saturate(dot(normal, hVector)), SpecularPower);

	return AmbientIntensity * AmbientColor + intensity * DiffuseColor + spec;

}

technique BlinnPhong
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 BlinnPhongVertexShader();
		PixelShader  = compile ps_2_0 BlinnPhongPixelShader();
	}
}