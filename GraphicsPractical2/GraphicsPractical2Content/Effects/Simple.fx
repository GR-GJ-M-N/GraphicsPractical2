//------------------------------------------- Defines -------------------------------------------

#define Pi 3.14159265

//------------------------------------- Top Level Variables -------------------------------------

// Top level variables can and have to be set at runtime

// Matrices for 3D perspective projection 
float4x4 View, Projection, World;
float3x3 InvTransposed;
float4 DiffuseColor, AmbientColor, SpecularColor;
float3 Light, Camera;
float AmbientIntensity, SpecularIntensity, SpecularPower, NormalMapIntensity;
texture QuadTexture, NormalMap;
sampler2D textureSampler = sampler_state{
	Texture = <QuadTexture>;
	MagFilter = Linear;
	MinFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};
sampler2D normalSampler = sampler_state{
	Texture = <NormalMap>;
	MagFilter = Linear;
	MinFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};

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
	float2 TextureCoord : TEXCOORD0;
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
	float3 Normal : TEXCOORD0;
	float3 WorldPosition : TEXCOORD1;
	float2 TextureCoord : TEXCOORD2;
	float3 Place : TEXCOORD3;
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
	// +3 to avoid having any problems with points which involve a 0
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

//---------------------------------------- Technique: 2.1 Lambertian ----------------------------------------

VertexShaderOutput LambertianVertexShader(VertexShaderInput input)
{
	// Allocate an empty output struct
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Do the matrix multiplications for perspective projection and the world transform
	float4 worldPosition = mul(input.Position3D, World);
    float4 viewPosition  = mul(worldPosition, View);
	output.Position2D    = mul(viewPosition, Projection);
	output.Normal = input.Normal3D.xyz;	
	output.Place = worldPosition.xyz;

	return output;
}

float4 LambertianPixelShader(VertexShaderOutput input) : COLOR0
{
	float3x3 rotationAndScale = (float3x3) World;
	float3 normal = input.Normal;
	normal = mul(normal, InvTransposed);

	//Normalize the normal
	normal = normalize(normal);

	//Calculate L
	float3 lVector = normalize(Light - input.Place);

	//Calculate n dot l, clamp to 0, 1
	float intensity = saturate(dot(normal, lVector));

	return AmbientIntensity * AmbientColor + intensity * DiffuseColor;
	//return float4(input.WorldPosition, 1);
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
	output.Place = worldPosition.xyz;
	output.Normal = input.Normal3D.xyz;	

	return output;
}

float4 BlinnPhongPixelShader(VertexShaderOutput input) : COLOR0
{
	float3x3 rotationAndScale = (float3x3) World;
	float3 normal = input.Normal;
	normal = mul(normal, InvTransposed);

	//Normalize the normal
	normal = normalize(normal);

	//Calculate L
	float3 lVector = normalize(Light - input.Place);

	//Calculate v (the vector to the camera)
	float3 vVector = normalize(Camera - input.Place);
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

//---------------------------------------- Technique: 3 Texture ----------------------------------------

VertexShaderOutput TextureVertexShader(VertexShaderInput input)
{
	// Allocate an empty output struct
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Do the matrix multiplications for perspective projection and the world transform
	float4 worldPosition = mul(input.Position3D, World);
    float4 viewPosition  = mul(worldPosition, View);
	output.Position2D    = mul(viewPosition, Projection);
	output.Normal = input.Normal3D.xyz;
	output.TextureCoord = input.TextureCoord;

	return output;
}

float4 TexturePixelShader(VertexShaderOutput input) : COLOR0
{
	float4 textureColor = tex2D(textureSampler, input.TextureCoord);

	return textureColor;
}

technique Texture
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 TextureVertexShader();
		PixelShader  = compile ps_2_0 TexturePixelShader();
	}
}

//---------------------------------------- Technique: 5 Texture(normal mapped) --------------------------

VertexShaderOutput TextureNormalVertexShader(VertexShaderInput input)
{
	// Allocate an empty output struct
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Do the matrix multiplications for perspective projection and the world transform
	float4 worldPosition = mul(input.Position3D, World);
    float4 viewPosition  = mul(worldPosition, View);
	output.Position2D    = mul(viewPosition, Projection);
	output.Place = worldPosition.xyz;
	output.Normal = input.Normal3D.xyz;
	output.TextureCoord = input.TextureCoord;

	return output;
}

float4 TextureNormalPixelShader(VertexShaderOutput input) : COLOR0
{
	float4 textureColor = tex2D(textureSampler, input.TextureCoord);

	float3x3 rotationAndScale = (float3x3) World;
	float3 normal = input.Normal;
	normal = mul(normal, InvTransposed);
	float3 tLight = mul(rotationAndScale, Light);

	//Do normal mapping
	float4 normalColor = tex2D(normalSampler, input.TextureCoord);
	float3 bumpNormal = (float3)normalColor * NormalMapIntensity;

	normal = normal + bumpNormal;

	//Normalize the normal
	normal = normalize(normal);

	//Calculate L
	float3 lVector = normalize(tLight - input.Place);

	//Calculate v (the vector to the camera)
	float3 vVector = normalize(Camera - input.Place);

	float3 hVector = (vVector + lVector) / length(vVector + lVector);

	//Calculate n dot l, clamp to 0, 1
	float intensity = saturate(dot(normal, lVector));
	float spec = SpecularColor * SpecularIntensity * pow(saturate(dot(normal, hVector)), SpecularPower);

	return intensity * textureColor + spec;
	//return float4(bumpNormal, 0);

}

technique TextureNormal
{
	pass Pass0
	{
		VertexShader = compile vs_2_0 TextureNormalVertexShader();
		PixelShader  = compile ps_2_0 TextureNormalPixelShader();
	}
}