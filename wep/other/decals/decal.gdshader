shader_type spatial;
render_mode world_vertex_coords, shadows_disabled
	, depth_test_disabled, cull_front // Hack to mitigate clipping when decal is close to the camera.
;

const lowp float CUBE_HALF_SIZE = 0.5;

uniform mediump vec4 modulate: source_color = vec4(1);
uniform mediump sampler2D texture_albedo: source_color, repeat_disable, filter_linear;
uniform lowp sampler2D DEPTH_TEXTURE: hint_depth_texture;
uniform lowp sampler2D SCREEN_TEXTURE: hint_screen_texture;
#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
	uniform lowp sampler2D NORMAL_TEXTURE: hint_normal_roughness_texture;
#endif

float remap(const float value, const float istart, const float istop, const float ostart, const float ostop) {
	float t = (value - istart) / (istop - istart);
	return (1.0 - t) * ostart + ostop * t;
}

#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	//vec4 srgb_to_linear(vec4 sRGB) {
	    //bvec3 cutoff = lessThan(sRGB.rgb, vec3(0.04045));
	    //vec3 higher = pow((sRGB.rgb + vec3(0.055))/vec3(1.055), vec3(2.4));
	    //vec3 lower = sRGB.rgb/vec3(12.92);
//
	    //return vec4(mix(higher, lower, cutoff), sRGB.a);
	//}

	vec4 linear_to_srgb(const vec4 linearRGB) {
	    bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
	    vec3 higher = vec3(1.055)*pow(linearRGB.rgb, vec3(1.0/2.4)) - vec3(0.055);
	    vec3 lower = linearRGB.rgb * vec3(12.92);

	    return vec4(mix(higher, lower, cutoff), linearRGB.a);
	}
#endif

// Credit: https://stackoverflow.com/questions/32227283/getting-world-position-from-depth-buffer-value
vec3 world_pos_from_depth(const float depth, vec2 screen_uv, mat4 inverse_projection_matrix, mat4 inverse_view_matrix) {
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		float z = depth * 2.0 - 1.0;
	#else
		float z = depth;
	#endif

	vec4 clip_space_position = vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec4 view_space_position = inverse_projection_matrix * clip_space_position;

	view_space_position /= view_space_position.w; // Adjust for perspective.

	vec4 world_space_position = inverse_view_matrix * view_space_position;

	return world_space_position.xyz;
}

vec4 blend_modulate2x(const vec4 base, const vec4 blend) {
	vec4 result = base * blend * 2.0;
	//vec4 result = base;

	//float influence = 0.2126 * base.r + 0.7152 * base.g + 0.0722 * base.b; // Luminance.
	//float influence = (base.r + base.g + base.b) / 3.0; // Grayscale.
	float influence = min(min(base.r, base.g), base.b); // Huh.
	//float influence = (min(min(base.r, base.g), base.b) + max(max(base.r, base.g), base.b)) / 2.0; // Lightness.
	// Inefficient but understandable. The further from middle gray the decal's color is, the more opaque it is.
	if (influence > 0.5) {
		result.a = remap(influence, 1.0, 0.5, 1.0, 0.0);
	} else {
		result.a = remap(influence, 0.0, 0.5, 1.0, 0.0);
	}

	//result.a = clamp(result.a * base.a, 0.0, 1.0);
	result.a *= base.a;

	return result;
}

varying mat4 INV_MODEL_MATRIX;

void vertex() {
	INV_MODEL_MATRIX = inverse(MODEL_MATRIX);
	//INV_MODEL_MATRIX *= 0.9 + sin(TIME) * 0.1;
	//VERTEX.x += sin(TIME) * 0.9;

	//POSITION = vec4(VERTEX.xy * 0.15, 0.2, 0.2);
	//vec4 world_position = vec4(VERTEX, 1.0);
	//vec4 view_pos = VIEW_MATRIX * world_position;
	//vec4 clip_pos = PROJECTION_MATRIX * view_pos;
	//POSITION = vec4((clip_pos.xy / clip_pos.w), 0.9, 1.0);
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 world_pos = world_pos_from_depth(depth, SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	vec4 local_pos = INV_MODEL_MATRIX * vec4(world_pos, 1.0);

	vec4 source = texture(texture_albedo, local_pos.xz + 0.5);
	if (source.a < 0.001) {
		discard;
	}
	if (abs(local_pos.x) > CUBE_HALF_SIZE ||
		abs(local_pos.y) > CUBE_HALF_SIZE ||
		abs(local_pos.z) > CUBE_HALF_SIZE) {
		discard; // Also an optimization for fading step.
	}

	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);

	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		screen = linear_to_srgb(screen);
	#else
		source.rgb *= 2.4; // Hack...? What an unusual magic number.
	#endif

	vec4 blended_result = blend_modulate2x(source, screen);

	ALBEDO = blended_result.rgb * modulate.rgb;
	ALPHA = blended_result.a * modulate.a;

	#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
		NORMAL = texture(NORMAL_TEXTURE, SCREEN_UV).rgb;
	#else
		NORMAL = vec3(0.0);
		//NORMAL = vec3(0.0, 1.0, 0.0);
		//NORMAL = (vec4(0.0, 1.0, 0.0, 1.0) * MODEL_MATRIX).xyz;
	#endif

	// Y fade. The further from the center the surface is, the more transparent the decal appears.
	//float fade = 1.0 - smoothstep(0.75, 1.0, clamp(remap(-CUBE_HALF_SIZE, CUBE_HALF_SIZE, 0.0, 1.0, local_pos.y), 0.0, 1.0));
	ALPHA *= clamp(1.75 - (0.5 + abs(local_pos.y * 2.5)), 0.0, 1.0);

	// Normal fade. The more slanted the surface is, the more transparent the decal appears.
	// TODO: Normal fade on Compatibility renderer as well.
	#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
		vec3 view_normal = NORMAL * 2.0 - 1.0;
		vec3 world_normal = (INV_VIEW_MATRIX * vec4(view_normal, 0.0)).xyz;
		ALPHA *= smoothstep(0.0, 1.0, dot(world_normal, MODEL_NORMAL_MATRIX[1]) * 0.5 + 0.5);
	#endif

	//ALBEDO = NORMAL;
	//ALBEDO = vec3(depth * 16.0, 0, 0);
	//LIGHT_VERTEX = vec3(local_pos.xyz);
}
