using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.GamerServices;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;

namespace GraphicsPractical2
{
    public class Game1 : Microsoft.Xna.Framework.Game
    {
        // Often used XNA objects
        private GraphicsDeviceManager graphics;
        private SpriteBatch spriteBatch;
        private FrameRateCounter frameRateCounter;

        // Game objects and variables
        private Camera camera;
        
        // Model
        private Model model;
        private Material modelMaterial;

        // Quad
        private VertexPositionNormalTexture[] quadVertices;
        private short[] quadIndices;
        private Matrix quadTransform;
        private Texture quadTexture;

        public Game1()
        {
            this.graphics = new GraphicsDeviceManager(this);
            this.Content.RootDirectory = "Content";
            // Create and add a frame rate counter
            this.frameRateCounter = new FrameRateCounter(this);
            this.Components.Add(this.frameRateCounter);
        }

        protected override void Initialize()
        {
            // Copy over the device's rasterizer state to change the current fillMode
            this.GraphicsDevice.RasterizerState = new RasterizerState() { CullMode = CullMode.None };
            // Set up the window
            this.graphics.PreferredBackBufferWidth = 800;
            this.graphics.PreferredBackBufferHeight = 600;
            this.graphics.IsFullScreen = false;
            // Let the renderer draw and update as often as possible
            this.graphics.SynchronizeWithVerticalRetrace = false;
            this.IsFixedTimeStep = false;
            // Flush the changes to the device parameters to the graphics card
            this.graphics.ApplyChanges();
            // Initialize the camera
            this.camera = new Camera(new Vector3(0, 50, 100), new Vector3(0, 0, 0), new Vector3(0, 1, 0));

            this.IsMouseVisible = true;

            base.Initialize();
        }

        protected override void LoadContent()
        {
            // Create a SpriteBatch object
            this.spriteBatch = new SpriteBatch(this.GraphicsDevice);
            // Load the "Simple" effect
            Effect effect = this.Content.Load<Effect>("Effects/Simple");
            // Load the model and let it use the "Simple" effect
            this.model = this.Content.Load<Model>("Models/Teapot");
            this.model.Meshes[0].MeshParts[0].Effect = effect;
            
            //2.1 start
            modelMaterial = new Material();
            modelMaterial.DiffuseColor = Color.Red;
            modelMaterial.AmbientColor = Color.Red;
            modelMaterial.AmbientIntensity = 0.2f;
            modelMaterial.SpecularColor = Color.White;
            modelMaterial.SpecularIntensity = 2.0f;
            modelMaterial.SpecularPower = 25.0f;
            modelMaterial.SetEffectParameters(effect);

            effect.Parameters["Light"].SetValue(new Vector3(50.0f, 50.0f, 50.0f));
            effect.Parameters["Camera"].SetValue(this.camera.Eye);
            //2.1 end

            // Setup the quad
            this.setupQuad();
            this.quadTexture = Content.Load<Texture>("Textures/CobblestonesDiffuse");
        }

        /// <summary>
        /// Sets up a 2 by 2 quad around the origin.
        /// </summary>
        private void setupQuad()
        {
            float scale = 50.0f;

            // Normal points up
            Vector3 quadNormal = new Vector3(0, 1, 0);

            this.quadVertices = new VertexPositionNormalTexture[4];
            // Top left
            this.quadVertices[0].Position = new Vector3(-1, 0, -1);
            this.quadVertices[0].Normal = quadNormal;
            this.quadVertices[0].TextureCoordinate = new Vector2(-1, -1);
            // Top right
            this.quadVertices[1].Position = new Vector3(1, 0, -1);
            this.quadVertices[1].Normal = quadNormal;
            this.quadVertices[1].TextureCoordinate = new Vector2(1, -1);
            // Bottom left
            this.quadVertices[2].Position = new Vector3(-1, 0, 1);
            this.quadVertices[2].Normal = quadNormal;
            this.quadVertices[2].TextureCoordinate = new Vector2(-1, 1);
            // Bottom right
            this.quadVertices[3].Position = new Vector3(1, 0, 1);
            this.quadVertices[3].Normal = quadNormal;
            this.quadVertices[3].TextureCoordinate = new Vector2(1, 1);

            this.quadIndices = new short[] { 0, 1, 2, 1, 2, 3 };
            this.quadTransform = Matrix.CreateScale(scale);
            Matrix translation = Matrix.CreateTranslation(0, -15.0f, 0);
            this.quadTransform = Matrix.Multiply(this.quadTransform, translation);
        }

        protected override void Update(GameTime gameTime)
        {
            float timeStep = (float)gameTime.ElapsedGameTime.TotalSeconds * 60.0f;

            // Update the window title
            this.Window.Title = "XNA Renderer | FPS: " + this.frameRateCounter.FrameRate;

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {

            // Clear the screen in a predetermined color and clear the depth buffer
            this.GraphicsDevice.Clear(ClearOptions.Target | ClearOptions.DepthBuffer, Color.DeepSkyBlue, 1.0f, 0);

            Matrix world = Matrix.CreateScale(10.0f);

            Effect quadEffect = this.Content.Load<Effect>("Effects/Simple");
            quadEffect.Parameters["QuadTexture"].SetValue(this.quadTexture);
            quadEffect.Parameters["World"].SetValue(this.quadTransform);
            quadEffect.CurrentTechnique = quadEffect.Techniques["Texture"];
            this.camera.SetEffectParameters(quadEffect);

            foreach (EffectPass pass in quadEffect.CurrentTechnique.Passes)
            {
                pass.Apply();
                this.GraphicsDevice.DrawUserIndexedPrimitives(PrimitiveType.TriangleList, this.quadVertices, 0, 4, this.quadIndices, 0, 2, VertexPositionNormalTexture.VertexDeclaration);
            }

            // Get the model's only mesh
            ModelMesh mesh = this.model.Meshes[0];
            Effect effect = mesh.Effects[0];

            // Set the effect parameters
            //effect.CurrentTechnique = effect.Techniques["Simple"]; //1.1 1.2
            //effect.CurrentTechnique = effect.Techniques["Lambertian"]; //2.1, 2.2
            effect.CurrentTechnique = effect.Techniques["BlinnPhong"]; //2.3

            // Matrices for 3D perspective projection
            this.camera.SetEffectParameters(effect);
            Matrix inverseTransposed = Matrix.Invert(Matrix.Transpose(world));
            effect.Parameters["World"].SetValue(world);
            effect.Parameters["InvTransposed"].SetValue(inverseTransposed);

            // Draw the model
            mesh.Draw();

            base.Draw(gameTime);
        }
    }
}
