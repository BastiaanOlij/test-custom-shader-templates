# Godot 4 Custom shader templates demo

This is a simple sample project to test the new custom shader templates logic.
Currently this showcases a Forward+ renderer custom shader template.

Requires: https://github.com/godotengine/godot/pull/94427

## Creating a custom shader template

To create a custom shader template simply create a new file with the `.gdtemplate` extension.
At the moment these can't be edited from within the Godot IDE and will need to be edited with a text editor.

At the bare minimum a shader template will look as follows:
```
shader_type spatial;

#[vertex]

#version 450

#VERSION_DEFINES

#define SHADER_IS_SRGB false

#include "standard_includes.glsl"
#include "input_attributes.glsl"

#GLOBALS

invariant gl_Position;

void main() {
    // Your vertex shader code goes here and should output gl_Position
}

#[fragment]

#version 450

#VERSION_DEFINES

#define SHADER_IS_SRGB false

#include "standard_includes.glsl"
#include "specialization_constants.glsl"
#include "output_buffers.glsl"

#GLOBALS

void main() {
    // Your fragment shader code goes here and should output to the
    // correct buffers for the variants being compiled.
}
```

### Variants

Godot will compile various variants of your shader.
These variants are controlled by defines that are injected into your shader where the `#VERSION_DEFINES` keyword is.

These defines can be combined to form different variations and new variants may be introduced in newer versions of Godot.
Depending on your needs you may not need to implement all variants however an unimplemented variant may result in breakage.

These are a number of core defines that steer variants:

|           Define              |                                      Description                                   |
|-------------------------------|------------------------------------------------------------------------------------|
| USE_MULTIVIEW                 | Stereo rendering is enabled, use `ViewIndex` to vary output for each eye.          |
| MODE_RENDER_DEPTH             | Rendering shadows or depth pre-pass.                                               |
| MODE_RENDER_MATERIAL          | Output albedo, normal, ORM, emission and depth data for lightmap/GI baking[^1].    |
| MODE_RENDER_NORMAL_ROUGHNESS  | Output roughness[^1].                                                              |
| MODE_RENDER_VOXEL_GI          | Output GI[^2].                                                                     |
| MODE_SEPARATE_SPECULAR        | Split color output into a diffuse and specular buffer.                             |
| MODE_DUAL_PARABOLOID          | Render output should be for a dual paraboloid shadow buffer[^1].                   |
| MODE_UNSHADED                 | No lighting should be performed (material is set to unshaded)                      |

> [!IMPORTANT]
> The defines above are based on the variants of the Forward+ renderer.
> Other renderers may support different defines or only a subset.
> We do try and keep defines the same over renderers when possible.

### The vertex and fragment shader

The `#VERTEX` keyword indicates the start of your vertex shader.
The `#FRAGMENT` keyword indicates the start of your fragment shader.
Unlike Godot user shaders there is no shared shader code between vertex and fragment shader code.
The lighting shader only exists as part of the user shader and should be injected into the fragment shader,
more about this in a minute.

You can write the shader completely from scratch however for ease of use we expose various built-in include files.
Where possible the names are unified and mapped to the correct include file for the renderer used.

The `#define SHADER_IS_SRGB false` is added to indicate our shader outputs linear color data.
For the compatibility renderer this should be set to `true`.

|        Include file            |                                     Description                                   |
|--------------------------------|-----------------------------------------------------------------------------------|
| standard_includes.glsl         | This includes all our uniform sets, data structures, etc.                         |
| specialization_constants.glsl  | This includes all our specialization constants.                                   |
| input_attributes.glsl          | This includes all input attributes (vertex shader only).                          |
| output_buffers.glsl            | This includes all output buffers (fragment shader only).                          |

> [!NOTE]
> Fully detailing out the include files with all the differences between the different renderers is near impossible.
> I've tried to provide the most important information in this writeup.
> If you wish to know more, it is best to consult Godots source code.
> The include files are nicely grouped together,
> for instance the `standard_includes.glsl` file for the forward+ renderer can be found here:
> [scene_forward_clustered_standard_inc.glsl](https://github.com/godotengine/godot/blob/master/servers/rendering/renderer_rd/shaders/forward_clustered/scene_forward_clustered_standard_inc.glsl)[^3]

### Uniform sets and data sources

Our `standard_includes.glsl` provides us access to a lot of global data that is updated each frame
and to our material data related to the given draw call.

This includes:
 - samplers,
 - data for light sources and reflection probes, etc,
 - scene data, e.g. view and projection matrices, viewport info, etc,[^4]
 - instance data,
 - input buffers,
 - material data.

Consult the relevant `standard_includes.glsl` file for the renderer for details.

### Specialization constants

Godot further allows specifying additional specialization constants to enable/disable certain features.
These are rendererer dependent and the syntax is different between OpenGL and RenderingDevice based renderers.

#### Forward+ Specialization constants

|  Specialization constant   |                     Description                            |
|----------------------------|------------------------------------------------------------|
| sc_use_forward_gi          | Use supplied forward GI data for lighting.                 |
| sc_use_light_projector     | Light projector data should be evaluated for spot lights.  |
| sc_use_light_soft_shadows  | Shadows should apply soft shadow logic.                    |
| sc_decal_use_mipmaps       | Decals have mipmaps you can use.                           |
| sc_projector_use_mipmaps   | Spot light projector have mipmaps you can use.             |
| sc_use_depth_fog           | Apply fog logic based on depth.                            |

#### Mobile Specialization constants

T.B.A.

#### Compatibility specialization constants

T.B.A.

### Input attributes

The input attributes of the vertex shader provide vertex data to process.
Note that many attributes are gated based on which are actually used in the user shader.
This is controlled by a number of `*_USED` defines.

|     Input attribute     |                Define                             |                 Description                        |
|-------------------------|---------------------------------------------------|----------------------------------------------------|
| vertex_angle_attrib     |                                                   | Vertex position and optional tangent angle.        |
| axis_tangent_attrib     | NORMAL_USED or TANGENT_USED                       | Tangent axis.                                      |
| color_attrib            | COLOR_USED                                        | Vertex color.                                      |
| uv_attrib               | UV_USED                                           | Vertex UV.                                         |
| uv2_attrib              | UV2_USED or USE_LIGHTMAP or MODE_RENDER_MATERIAL  | Vertex UV2.                                        |
| custom0_attrib          | CUSTOM0_USED                                      | Vertex custom attribute 0.                         |
| custom1_attrib          | CUSTOM1_USED                                      | Vertex custom attribute 1.                         |
| custom2_attrib          | CUSTOM2_USED                                      | Vertex custom attribute 2.                         |
| custom3_attrib          | CUSTOM3_USED                                      | Vertex custom attribute 3.                         |
| weight_attrib           | WEIGHTS_USED or USE_PARTICLE_TRAILS               | Vertex weights.                                    |
| previous_vertex_attrib  | MOTION_VECTORS                                    | Previous frame vertex position and tangent angle.  |
| previous_normal_attrib  | MOTION_VECTORS and (NORMAL_USED or TANGENT_USED)  | Previous frame tangent axis.                       |

> [!IMPORTANT]
> Some attributes are encoded to save on bandwidth.
> `input_attributes.glsl` contains a function called `_unpack_vertex_attributes` that allows you to unpack these.
> This functions parameters also react to the `*_USED` defines.
> See our example custom shader template on how to use this.

### Output buffers

These are the buffers the fragment shader outputs to.

Note that if `MODE_RENDER_DEPTH` is set there may be none as we're only populating the depth buffer.
The fragment shader in this scenario is only applicable if fragments can be discarded (alpha scissor).
Be sure to use defines properly to only include discards if this logic is required.
If the fragment shader can be skipped all together this has a performance benefit.

|          Output buffer          |                      Define                     |                   Description                     |
|---------------------------------|-------------------------------------------------|---------------------------------------------------|
| frag_color                      | !MODE_RENDER_DEPTH and !MODE_SEPARATE_SPECULAR  | Normal color output + alpha.                      |
| diffuse_buffer                  | MODE_SEPARATE_SPECULAR                          | Diffuse color output + roughness in alpha.        |
| specular_buffer                 | MODE_SEPARATE_SPECULAR                          | Specular output.                                  |
| albedo_output_buffer            | MODE_RENDER_MATERIAL                            | Albedo output.                                    |
| normal_output_buffer            | MODE_RENDER_MATERIAL                            | Normal vector output.                             |
| orm_output_buffer               | MODE_RENDER_MATERIAL                            | AO, roughness, metallic and sss_strength output.  |
| emission_output_buffer          | MODE_RENDER_MATERIAL                            | Emission color output.                            |
| depth_output_buffer             | MODE_RENDER_MATERIAL                            | Vertex depth output.                              |
| normal_roughness_output_buffer  | MODE_RENDER_NORMAL_ROUGHNESS                    | Normal vector and roughness output.               |
| voxel_gi_buffer                 | MODE_RENDER_VOXEL_GI                            | Voxel GI output.                                  |
| motion_vector                   | MOTION_VECTORS                                  | Motion vector output.                             |

> [!NOTE]
> Different renderers may have different or limited outputs.

### User shaders

Just like the built-in templates, custom shader templates are combined with user shaders created within Godot.
This included shaders created by Godots materials.

All applicable user shaders must be supported by your custom shader template or Godot will give an error.
If you do not wish to support one, just encompass it in an `ifdef`.

|        Code         |                           Description                                 |
|---------------------|-----------------------------------------------------------------------|
| `#CODE : VERTEX`    | User vertex shader code, include in template vertex shader code.      |
| `#CODE : FRAGMENT`  | User fragment shader code, include in template fragment shader code.  |
| `#CODE : LIGHT`     | User vertex shader code, include in template fragment shader code.    |

## Using the custom shader template

In order to use the custom shader template you need to add the `shader_template` keyword in your shader like so:
```
shader_type spatial;
shader_template "res://test.gdtemplate";
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

...
```

## License

This project is provided under the MIT license

Check license files in the asset and addons folders for 3rd party licenses.

[^1]: Always combined with `MODE_RENDER_DEPTH`
[^2]: Always combined with `MODE_RENDER_NORMAL_ROUGHNESS`
[^3]: Pending PR #94427
[^4]: If renderer supports motion vectors, this contains two copies, one for the previous frame and one for the current frame.