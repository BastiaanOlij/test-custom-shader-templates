// Standard inputs, defines and helper functions for mobile shaders
// Godot 4.7 dev5

/* half_inc.glsl */

// Use of FP16 in Godot is done explicitly through the types half and hvec.
// The extensions must be supported by the system to use this shader.
//
// If EXPLICIT_FP16 is not defined, all operations will use full precision
// floats instead and all casting operations will not be performed.

#ifndef HALF_INC_H
#define HALF_INC_H

#ifdef EXPLICIT_FP16

#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require
#extension GL_EXT_shader_16bit_storage : require

#define HALF_FLT_MIN float16_t(6.10352e-5)
#define HALF_FLT_MAX float16_t(65504.0)

#define half float16_t
#define hvec2 f16vec2
#define hvec3 f16vec3
#define hvec4 f16vec4
#define hmat2 f16mat2
#define hmat3 f16mat3
#define hmat4 f16mat4
#define saturateHalf(x) min(float16_t(x), HALF_FLT_MAX)

#else

#define HALF_FLT_MIN float(1.175494351e-38F)
#define HALF_FLT_MAX float(3.402823466e+38F)

#define half float
#define hvec2 vec2
#define hvec3 vec3
#define hvec4 vec4
#define hmat2 mat2
#define hmat3 mat3
#define hmat4 mat4
#define saturateHalf(x) (x)

#endif

#endif // HALF_INC_H

/* scene_forward_mobile_inc.glsl */

#define M_PI 3.14159265359
#define MAX_VIEWS 2

#ifdef USE_MULTIVIEW
#extension GL_EXT_multiview : enable
#define ViewIndex gl_ViewIndex
vec3 multiview_uv(vec2 uv) {
	return vec3(uv, ViewIndex);
}
ivec3 multiview_uv(ivec2 uv) {
	return ivec3(uv, int(ViewIndex));
}
#else // USE_MULTIVIEW
#define ViewIndex 0
vec2 multiview_uv(vec2 uv) {
	return uv;
}
ivec2 multiview_uv(ivec2 uv) {
	return uv;
}
#endif // !USE_MULTIVIEW

// decal_data_inc.glsl
struct DecalData {
	mat4 xform; //to decal transform
	vec3 inv_extents;
	float albedo_mix;
	vec4 albedo_rect;
	vec4 normal_rect;
	vec4 orm_rect;
	vec4 emission_rect;
	vec4 modulate;
	float emission_energy;
	uint mask;
	float upper_fade;
	float lower_fade;
	mat3x4 normal_xform;
	vec3 normal;
	float normal_fade;
};

#include "godot/scene_data_inc.glsl"

#if !defined(MODE_RENDER_DEPTH) || defined(MODE_RENDER_MATERIAL) || defined(TANGENT_USED) || defined(NORMAL_MAP_USED) || defined(BENT_NORMAL_MAP_USED) || defined(LIGHT_ANISOTROPY_USED)
#ifndef NORMAL_USED
#define NORMAL_USED
#endif
#endif

#define USING_MOBILE_RENDERER

layout(push_constant, std430) uniform DrawCall {
	uint uv_offset;
	uint instance_index;
	uint multimesh_motion_vectors_current_offset;
	uint multimesh_motion_vectors_previous_offset;
#ifdef UBERSHADER
	uint sc_packed_0;
	uint sc_packed_1;
	float sc_packed_2;
	uint uc_packed_0;
#endif
}
draw_call;

/* Specialization Constants */

#ifdef UBERSHADER

#define POLYGON_CULL_DISABLED 0
#define POLYGON_CULL_FRONT 1
#define POLYGON_CULL_BACK 2

// Pull the constants from the draw call's push constants.
uint sc_packed_0() {
	return draw_call.sc_packed_0;
}

uint sc_packed_1() {
	return draw_call.sc_packed_1;
}

float sc_packed_2() {
	return draw_call.sc_packed_2;
}

uint uc_cull_mode() {
	return (draw_call.uc_packed_0 >> 0) & 3U;
}

#else

// Pull the constants from the pipeline's specialization constants.
layout(constant_id = 0) const uint pso_sc_packed_0 = 0;
layout(constant_id = 1) const uint pso_sc_packed_1 = 0;
layout(constant_id = 2) const float pso_sc_packed_2 = 2.0;

uint sc_packed_0() {
	return pso_sc_packed_0;
}

uint sc_packed_1() {
	return pso_sc_packed_1;
}

float sc_packed_2() {
	return pso_sc_packed_2;
}

#endif

bool sc_use_light_projector() {
	return ((sc_packed_0() >> 0) & 1U) != 0;
}

bool sc_use_light_soft_shadows() {
	return ((sc_packed_0() >> 1) & 1U) != 0;
}

bool sc_use_directional_soft_shadows() {
	return ((sc_packed_0() >> 2) & 1U) != 0;
}

bool sc_decal_use_mipmaps() {
	return ((sc_packed_0() >> 3) & 1U) != 0;
}

bool sc_projector_use_mipmaps() {
	return ((sc_packed_0() >> 4) & 1U) != 0;
}

bool sc_disable_fog() {
	return ((sc_packed_0() >> 5) & 1U) != 0;
}

bool sc_use_depth_fog() {
	return ((sc_packed_0() >> 6) & 1U) != 0;
}

bool sc_use_fog_aerial_perspective() {
	return ((sc_packed_0() >> 7) & 1U) != 0;
}

bool sc_use_fog_sun_scatter() {
	return ((sc_packed_0() >> 8) & 1U) != 0;
}

bool sc_use_fog_height_density() {
	return ((sc_packed_0() >> 9) & 1U) != 0;
}

bool sc_use_lightmap_bicubic_filter() {
	return ((sc_packed_0() >> 10) & 1U) != 0;
}

bool sc_use_material_debanding() {
	return ((sc_packed_0() >> 11) & 1U) != 0;
}

bool sc_multimesh() {
	return ((sc_packed_0() >> 12) & 1U) != 0;
}

bool sc_multimesh_format_2d() {
	return ((sc_packed_0() >> 13) & 1U) != 0;
}

bool sc_multimesh_has_color() {
	return ((sc_packed_0() >> 14) & 1U) != 0;
}

bool sc_multimesh_has_custom_data() {
	return ((sc_packed_0() >> 15) & 1U) != 0;
}

bool sc_scene_use_ambient_cubemap() {
	return ((sc_packed_0() >> 16) & 1U) != 0;
}

bool sc_scene_use_reflection_cubemap() {
	return ((sc_packed_0() >> 17) & 1U) != 0;
}

bool sc_scene_roughness_limiter_enabled() {
	return ((sc_packed_0() >> 18) & 1U) != 0;
}

uint sc_soft_shadow_samples() {
	return (sc_packed_0() >> 20) & 63U;
}

uint sc_penumbra_shadow_samples() {
	return (sc_packed_0() >> 26) & 63U;
}

uint sc_directional_soft_shadow_samples() {
	return (sc_packed_1() >> 0) & 63U;
}

uint sc_directional_penumbra_shadow_samples() {
	return (sc_packed_1() >> 6) & 63U;
}

#define SHADER_COUNT_NONE 0
#define SHADER_COUNT_SINGLE 1
#define SHADER_COUNT_MULTIPLE 2

uint option_to_count(uint option, uint bound) {
	switch (option) {
		case SHADER_COUNT_NONE:
			return 0;
		case SHADER_COUNT_SINGLE:
			return 1;
		case SHADER_COUNT_MULTIPLE:
			return bound;
	}
}

uint sc_omni_lights(uint bound) {
	uint option = (sc_packed_1() >> 12) & 3U;
	return option_to_count(option, bound);
}

uint sc_spot_lights(uint bound) {
	uint option = (sc_packed_1() >> 14) & 3U;
	return option_to_count(option, bound);
}

uint sc_area_lights(uint bound) {
	uint option = (sc_packed_1() >> 16) & 3U;
	return option_to_count(option, bound);
}

uint sc_reflection_probes(uint bound) {
	uint option = (sc_packed_1() >> 18) & 3U;
	return option_to_count(option, bound);
}

uint sc_directional_lights(uint bound) {
	uint option = (sc_packed_1() >> 20) & 3U;
	return option_to_count(option, bound);
}

uint sc_decals(uint bound) {
	if (((sc_packed_1() >> 22) & 1U) != 0) {
		return bound;
	} else {
		return 0;
	}
}

bool sc_directional_light_blend_split(uint i) {
	return ((sc_packed_1() >> (23 + i)) & 1U) != 0;
}

half sc_luminance_multiplier() {
	return half(sc_packed_2());
}

layout(constant_id = 3) const bool sc_emulate_point_size = false;

/* Set 0: Base Pass (never changes) */

// light_data_inc.glsl

#define LIGHT_BAKE_DISABLED 0
#define LIGHT_BAKE_STATIC 1
#define LIGHT_BAKE_DYNAMIC 2

struct LightData { //this structure needs to be as packed as possible
	vec3 position;
	float inv_radius;

	vec3 direction;
	float size;

	vec3 color;
	float attenuation;

	float cone_attenuation;
	float cone_angle;
	float specular_amount;
	float shadow_opacity;

	vec4 atlas_rect; // rect in the shadow atlas
	mat4 shadow_matrix;
	float shadow_bias;
	float shadow_normal_bias;
	float transmittance_bias;
	float soft_shadow_size; // for spot, it's the size in uv coordinates of the light, for omni it's the span angle
	float soft_shadow_scale; // scales the shadow kernel for blurrier shadows
	uint mask;
	float volumetric_fog_energy;
	uint bake_mode;
	vec4 projector_rect; //projector rect in srgb decal atlas
};

#define REFLECTION_AMBIENT_DISABLED 0
#define REFLECTION_AMBIENT_ENVIRONMENT 1
#define REFLECTION_AMBIENT_COLOR 2

struct ReflectionData {
	vec3 box_extents;
	float index;
	vec3 box_offset;
	uint mask;
	vec3 ambient; // ambient color
	float intensity;
	float blend_distance;
	bool exterior;
	bool box_project;
	uint ambient_mode;
	float exposure_normalization;
	float pad0;
	float pad1;
	float pad2;
	//0-8 is intensity,8-9 is ambient, mode
	mat4 local_matrix; // up to here for spot and omni, rest is for directional
	// notes: for ambientblend, use distance to edge to blend between already existing global environment
};

struct DirectionalLightData {
	vec3 direction;
	float energy; // needs to be highp to avoid NaNs being created with high energy values (i.e. when using physical light units and over-exposing the image)
	vec3 color;
	float size;
	float specular;
	uint mask;
	float softshadow_angle;
	float soft_shadow_scale;
	bool blend_splits;
	float shadow_opacity;
	float fade_from;
	float fade_to;
	uvec2 pad;
	uint bake_mode;
	float volumetric_fog_energy;
	vec4 shadow_bias;
	vec4 shadow_normal_bias;
	vec4 shadow_transmittance_bias;
	vec4 shadow_z_range;
	vec4 shadow_range_begin;
	vec4 shadow_split_offsets;
	mat4 shadow_matrix1;
	mat4 shadow_matrix2;
	mat4 shadow_matrix3;
	mat4 shadow_matrix4;
	vec2 uv_scale1;
	vec2 uv_scale2;
	vec2 uv_scale3;
	vec2 uv_scale4;
};

layout(set = 0, binding = 2) uniform sampler shadow_sampler;

#define INSTANCE_FLAGS_DYNAMIC (1 << 3)
#define INSTANCE_FLAGS_NON_UNIFORM_SCALE (1 << 4)
#define INSTANCE_FLAGS_USE_GI_BUFFERS (1 << 5)
#define INSTANCE_FLAGS_USE_SDFGI (1 << 6)
#define INSTANCE_FLAGS_USE_LIGHTMAP_CAPTURE (1 << 7)
#define INSTANCE_FLAGS_USE_LIGHTMAP (1 << 8)
#define INSTANCE_FLAGS_USE_SH_LIGHTMAP (1 << 9)
#define INSTANCE_FLAGS_USE_VOXEL_GI (1 << 10)
#define INSTANCE_FLAGS_PARTICLES (1 << 11)
#define INSTANCE_FLAGS_PARTICLE_TRAIL_SHIFT 16
//3 bits of stride
#define INSTANCE_FLAGS_PARTICLE_TRAIL_MASK 0xFF

layout(set = 0, binding = 3, std430) restrict readonly buffer OmniLights {
	LightData data[];
}
omni_lights;

layout(set = 0, binding = 4, std430) restrict readonly buffer SpotLights {
	LightData data[];
}
spot_lights;

layout(set = 0, binding = 5, std430) restrict readonly buffer AreaLights {
	LightData data[];
}
area_lights;

layout(set = 0, binding = 6, std430) restrict readonly buffer ReflectionProbeData {
	ReflectionData data[];
}
reflections;

layout(set = 0, binding = 7, std140) uniform DirectionalLights {
	DirectionalLightData data[MAX_DIRECTIONAL_LIGHT_DATA_STRUCTS];
}
directional_lights;

#define LIGHTMAP_FLAG_USE_DIRECTION 1
#define LIGHTMAP_FLAG_USE_SPECULAR_DIRECTION 2

#define LIGHTMAP_SHADOWMASK_MODE_NONE 0
#define LIGHTMAP_SHADOWMASK_MODE_REPLACE 1
#define LIGHTMAP_SHADOWMASK_MODE_OVERLAY 2
#define LIGHTMAP_SHADOWMASK_MODE_ONLY 3

struct Lightmap {
	mat3 normal_xform;
	vec2 light_texture_size;
	float exposure_normalization;
	uint flags;
};

layout(set = 0, binding = 8, std140) restrict readonly buffer Lightmaps {
	Lightmap data[];
}
lightmaps;

struct LightmapCapture {
	vec4 sh[9];
};

layout(set = 0, binding = 9, std140) restrict readonly buffer LightmapCaptures {
	LightmapCapture data[];
}
lightmap_captures;

layout(set = 0, binding = 10) uniform texture2D decal_atlas;
layout(set = 0, binding = 11) uniform texture2D decal_atlas_srgb;

layout(set = 0, binding = 12, std430) restrict readonly buffer Decals {
	DecalData data[];
}
decals;

layout(set = 0, binding = 13, std430) restrict readonly buffer GlobalShaderUniformData {
	vec4 data[];
}
global_shader_uniforms;

layout(set = 0, binding = 14) uniform sampler DEFAULT_SAMPLER_LINEAR_WITH_MIPMAPS_CLAMP;

layout(set = 0, binding = 15) uniform sampler2D ltc_lut1;

layout(set = 0, binding = 16) uniform sampler2D ltc_lut2;

layout(set = 0, binding = 17) uniform texture2D area_light_atlas;

/* Set 1: Render Pass (changes per render pass) */

layout(set = 1, binding = 0, std140) uniform SceneDataBlock {
	SceneData data;
	SceneData prev_data;
}
scene_data_block;

struct InstanceData {
	highp mat3x4 transform;
	vec4 compressed_aabb_position_pad; // Only .xyz is used. .w is padding.
	vec4 compressed_aabb_size_pad; // Only .xyz is used. .w is padding.
	vec4 uv_scale;
	uint flags;
	uint instance_uniforms_ofs; // Base offset in global buffer for instance variables.
	uint gi_offset; // GI information when using lightmapping (VCT or lightmap index).
	uint layer_mask;
	highp mat3x4 prev_transform;

	vec4 lightmap_uv_scale; // Doubles as uv_offset when needed.
	uvec2 reflection_probes;
	uvec2 omni_lights;
	uvec2 spot_lights;
	uvec2 area_lights;
	uvec2 decals;
	uvec2 padding;
#ifdef USE_DOUBLE_PRECISION
	vec4 model_precision;
	vec4 prev_model_precision;
#endif
};

layout(set = 1, binding = 1, std430) buffer restrict readonly InstanceDataBuffer {
	InstanceData data[];
}
instances;

#ifdef USE_RADIANCE_CUBEMAP_ARRAY

layout(set = 1, binding = 2) uniform textureCubeArray radiance_cubemap;

#else

layout(set = 1, binding = 2) uniform textureCube radiance_cubemap;

#endif

layout(set = 1, binding = 3) uniform textureCubeArray reflection_atlas;

layout(set = 1, binding = 4) uniform texture2D shadow_atlas;

layout(set = 1, binding = 5) uniform texture2D directional_shadow_atlas;

// this needs to change to providing just the lightmap we're using..
layout(set = 1, binding = 6) uniform texture2DArray lightmap_textures[MAX_LIGHTMAP_TEXTURES * 2];

#ifdef USE_MULTIVIEW
layout(set = 1, binding = 9) uniform texture2DArray depth_buffer;
layout(set = 1, binding = 10) uniform texture2DArray color_buffer;
#define multiviewSampler sampler2DArray
#else
layout(set = 1, binding = 9) uniform texture2D depth_buffer;
layout(set = 1, binding = 10) uniform texture2D color_buffer;
#define multiviewSampler sampler2D
#endif // USE_MULTIVIEW

layout(set = 1, binding = 11) uniform sampler decal_sampler;

layout(set = 1, binding = 12) uniform sampler light_projector_sampler;

layout(set = 1, binding = 13 + 0) uniform sampler SAMPLER_NEAREST_CLAMP;
layout(set = 1, binding = 13 + 1) uniform sampler SAMPLER_LINEAR_CLAMP;
layout(set = 1, binding = 13 + 2) uniform sampler SAMPLER_NEAREST_WITH_MIPMAPS_CLAMP;
layout(set = 1, binding = 13 + 3) uniform sampler SAMPLER_LINEAR_WITH_MIPMAPS_CLAMP;
layout(set = 1, binding = 13 + 4) uniform sampler SAMPLER_NEAREST_WITH_MIPMAPS_ANISOTROPIC_CLAMP;
layout(set = 1, binding = 13 + 5) uniform sampler SAMPLER_LINEAR_WITH_MIPMAPS_ANISOTROPIC_CLAMP;
layout(set = 1, binding = 13 + 6) uniform sampler SAMPLER_NEAREST_REPEAT;
layout(set = 1, binding = 13 + 7) uniform sampler SAMPLER_LINEAR_REPEAT;
layout(set = 1, binding = 13 + 8) uniform sampler SAMPLER_NEAREST_WITH_MIPMAPS_REPEAT;
layout(set = 1, binding = 13 + 9) uniform sampler SAMPLER_LINEAR_WITH_MIPMAPS_REPEAT;
layout(set = 1, binding = 13 + 10) uniform sampler SAMPLER_NEAREST_WITH_MIPMAPS_ANISOTROPIC_REPEAT;
layout(set = 1, binding = 13 + 11) uniform sampler SAMPLER_LINEAR_WITH_MIPMAPS_ANISOTROPIC_REPEAT;

/* Set 2 Skeleton & Instancing (can change per item) */

layout(set = 2, binding = 0, std430) restrict readonly buffer Transforms {
	vec4 data[];
}
transforms;

/* Set 3 User Material */

#ifdef MATERIAL_UNIFORMS_USED
layout(set = MATERIAL_UNIFORM_SET, binding = 0, std140) uniform MaterialUniforms {
#MATERIAL_UNIFORMS
} material;
#endif
