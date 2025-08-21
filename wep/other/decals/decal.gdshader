shader_type spatial;
render_mode world_vertex_coords, shadows_disabled
	// Technically a hack.
	//, unshaded
	//, depth_test_disabled
	//, cull_disabled
;
uniform mediump vec4 modulate: source_color = vec4(1);
uniform mediump sampler2D texture_albedo: source_color, repeat_disable, filter_linear;
uniform lowp sampler2D DEPTH_TEXTURE: hint_depth_texture;
uniform lowp sampler2D SCREEN_TEXTURE: hint_screen_texture;
#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
	uniform lowp sampler2D NORMAL_TEXTURE: hint_normal_roughness_texture;
#endif

varying mat4 INV_MODEL_MATRIX;

void vertex(){
	INV_MODEL_MATRIX = inverse(MODEL_MATRIX);
	//INV_MODEL_MATRIX *= 0.9 + sin(TIME) * 0.1;
	//VERTEX.x += sin(TIME) * 0.5;
}

float remap(float i_min, float i_max, float o_min, float o_max, float v) {
	float t = (v - i_min) / (i_max - i_min);
	return (1.0 - t) * o_min + o_max * t;
}

vec4 srgb_to_linear(vec4 sRGB) {
    bvec3 cutoff = lessThan(sRGB.rgb, vec3(0.04045));
    vec3 higher = pow((sRGB.rgb + vec3(0.055))/vec3(1.055), vec3(2.4));
    vec3 lower = sRGB.rgb/vec3(12.92);

    return vec4(mix(higher, lower, cutoff), sRGB.a);
}

vec4 linear_to_srgb(vec4 linearRGB) {
    bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
    vec3 higher = vec3(1.055)*pow(linearRGB.rgb, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB.rgb * vec3(12.92);

    return vec4(mix(higher, lower, cutoff), linearRGB.a);
}

// Credit: https://stackoverflow.com/questions/32227283/getting-world-position-from-depth-buffer-value
vec3 world_pos_from_depth(float depth, vec2 screen_uv, mat4 inverse_proj, mat4 inverse_view) {
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		float z = depth * 2.0 - 1.0;
	#else
		float z = depth;
	#endif

	vec4 clipSpacePosition = vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec4 viewSpacePosition = inverse_proj * clipSpacePosition;

	viewSpacePosition /= viewSpacePosition.w; // Adjust for perspective.

	vec4 worldSpacePosition = inverse_view * viewSpacePosition;

	return worldSpacePosition.xyz;
}

vec4 blend_modulate2x(vec4 base, vec4 blend, vec2 screen_uv) {
	vec4 result = base * blend * 2.0;
	//vec4 result = base;

	//float influence = 0.2126 * base.r + 0.7152 * base.g + 0.0722 * base.b; // Luminance.
	//float influence = (base.r + base.g + base.b) / 3.0; // Grayscale.
	float influence = min(min(base.r, base.g), base.b); // Huh.
	//float influence = (min(min(base.r, base.g), base.b) + max(max(base.r, base.g), base.b)) / 2.0; // Lightness.
	// Inefficient but understandable. The further from middle gray the decal's color is, the more opaque it is.
	if (influence > 0.5) {
		result.a = remap(1.0, 0.5, 1.0, 0.0, influence);
	} else {
		result.a = remap(0.0, 0.5, 1.0, 0.0, influence);
	}

	//result.a = clamp(result.a * base.a, 0.0, 1.0);
	result.a *= base.a;

	return result;
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 world_pos = world_pos_from_depth(depth, SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	vec4 test_pos = INV_MODEL_MATRIX * vec4(world_pos, 1.0);

	vec4 source = texture(texture_albedo, test_pos.xz + 0.5);
	if (source.a < 0.001) {
		discard;
	}

	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);

	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		screen = linear_to_srgb(screen);
	#else
		source.rgb *= 2.4; // Hack...? What an unusual magic number.
	#endif

	vec4 blended_result = blend_modulate2x(source, screen, SCREEN_UV);

	ALBEDO = blended_result.rgb * modulate.rgb;
	ALPHA = blended_result.a * modulate.a;

	#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
		NORMAL = texture(NORMAL_TEXTURE, SCREEN_UV).rgb;
	#else
		NORMAL = vec3(0.0);
		//NORMAL = vec3(0.0, 1.0, 0.0);
		//NORMAL = (vec4(0.0, 1.0, 0.0, 1.0) * MODEL_MATRIX).xyz;
	#endif

	//ALBEDO = NORMAL;
	//ALBEDO = vec3(depth * 16.0, 0, 0);
	//LIGHT_VERTEX = vec3(test_pos.xyz);
}
