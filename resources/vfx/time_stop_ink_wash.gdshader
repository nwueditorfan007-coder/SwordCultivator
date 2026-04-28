shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float entry_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float recover_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center_uv = vec2(0.5, 0.5);
uniform vec2 player_uv = vec2(0.5, 0.5);
uniform vec2 axis_dir = vec2(1.0, 0.0);
uniform vec3 cold_ink_color = vec3(0.66, 0.82, 1.0);
uniform vec3 paper_color = vec3(0.78, 0.83, 0.88);
uniform float ink_contrast = 0.58;
uniform float paper_grain = 0.085;
uniform float vignette_strength = 0.46;
uniform float focus_restore_strength = 0.78;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += value_noise(p) * amplitude;
		p = p * 2.07 + vec2(17.23, 9.41);
		amplitude *= 0.5;
	}
	return value;
}

float focus_signal(vec3 rgb) {
	float max_c = max(max(rgb.r, rgb.g), rgb.b);
	float min_c = min(min(rgb.r, rgb.g), rgb.b);
	float saturation = max_c - min_c;
	float cyan = smoothstep(0.10, 0.48, rgb.b + rgb.g - rgb.r * 0.72);
	float red = smoothstep(0.10, 0.44, rgb.r - max(rgb.g, rgb.b) * 0.64);
	float bright = smoothstep(0.16, 0.92, max_c);
	return clamp(max(cyan, red) * smoothstep(0.08, 0.42, saturation) * bright, 0.0, 1.0);
}

void fragment() {
	vec4 scene = textureLod(screen_texture, SCREEN_UV, 0.0);
	vec3 source = scene.rgb;
	float ink = clamp(pow(strength, 0.72), 0.0, 1.0);
	float pulse = clamp(entry_pulse, 0.0, 1.0);

	vec2 aspect_uv = SCREEN_UV - vec2(0.5);
	aspect_uv.x *= SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.0001);
	float edge_distance = length(aspect_uv);
	float vignette = smoothstep(0.36, 0.82, edge_distance);

	vec2 pulse_uv = SCREEN_UV - center_uv;
	pulse_uv.x *= SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.0001);
	float pulse_distance = length(pulse_uv);
	float wave_progress = 1.0 - pulse;
	float entry_ring = exp(-abs(pulse_distance - wave_progress * 0.95) * 21.0) * pulse;

	vec2 line_to_focus = center_uv - player_uv;
	float line_length = max(length(line_to_focus), 0.001);
	vec2 corridor_axis = normalize(mix(axis_dir, line_to_focus / line_length, 0.7));
	vec2 corridor_origin = mix(player_uv, center_uv, 0.42);
	vec2 corridor_uv = SCREEN_UV - corridor_origin;
	corridor_uv.x *= SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.0001);
	vec2 corridor_axis_aspect = corridor_axis;
	corridor_axis_aspect.x *= SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.0001);
	corridor_axis_aspect = normalize(corridor_axis_aspect);
	float corridor_along = dot(corridor_uv, corridor_axis_aspect);
	float corridor_side = abs(corridor_uv.x * corridor_axis_aspect.y - corridor_uv.y * corridor_axis_aspect.x);
	float corridor_half_length = max(line_length * 0.85, 0.08);
	float corridor_width = mix(0.035, 0.14, ink) + recover_progress * 0.045;
	float corridor_mask = smoothstep(corridor_half_length + 0.08, corridor_half_length * 0.45, abs(corridor_along));
	corridor_mask *= smoothstep(corridor_width, corridor_width * 0.25, corridor_side);
	float corridor_flow = 0.5 + 0.5 * sin(corridor_along * 42.0 - TIME * (4.8 + recover_progress * 2.2));
	corridor_flow *= smoothstep(corridor_width * 0.85, corridor_width * 0.08, corridor_side);
	float player_recover = 1.0 - smoothstep(0.06, 0.26, distance(SCREEN_UV, player_uv));
	float focus_recover = 1.0 - smoothstep(0.08, 0.34, distance(SCREEN_UV, center_uv));
	float recover_mask = clamp(max(corridor_mask, max(player_recover, focus_recover * 0.92)) * recover_progress, 0.0, 1.0);

	float luma = dot(source, vec3(0.299, 0.587, 0.114));
	float luma_contrast = clamp((luma - 0.5) * (1.0 + ink_contrast * ink + 0.18 * pulse) + 0.5, 0.0, 1.0);
	float broad_noise = fbm(SCREEN_UV * vec2(6.2, 3.7) + vec2(0.0, TIME * 0.018));
	float fibrous_noise = fbm(SCREEN_UV * vec2(38.0, 24.0) + vec2(TIME * 0.01, 0.0));
	float paper_noise = (broad_noise - 0.5) * 0.18 + (fibrous_noise - 0.5) * 0.08;
	float ink_bleed = smoothstep(0.18, 0.74, broad_noise + ink * 0.18 - luma * 0.22);

	vec3 gray_ink = vec3(luma_contrast);
	gray_ink = mix(gray_ink, gray_ink * cold_ink_color, 0.28 + 0.22 * ink);
	gray_ink = mix(gray_ink, paper_color * luma_contrast, 0.10 * ink);
	gray_ink -= ink_bleed * vec3(0.075, 0.083, 0.09) * ink;
	gray_ink += paper_noise * paper_grain * ink;
	gray_ink *= 1.0 - vignette * vignette_strength * ink;

	float desaturate = clamp(0.52 + 0.44 * ink + 0.22 * pulse, 0.0, 1.0);
	vec3 washed = mix(source, gray_ink, desaturate);

	float local_focus = focus_signal(source);
	float halo = 0.0;
	vec2 px = SCREEN_PIXEL_SIZE * 3.0;
	halo += focus_signal(textureLod(screen_texture, clamp(SCREEN_UV + vec2(px.x, 0.0), vec2(0.0), vec2(1.0)), 0.0).rgb);
	halo += focus_signal(textureLod(screen_texture, clamp(SCREEN_UV - vec2(px.x, 0.0), vec2(0.0), vec2(1.0)), 0.0).rgb);
	halo += focus_signal(textureLod(screen_texture, clamp(SCREEN_UV + vec2(0.0, px.y), vec2(0.0), vec2(1.0)), 0.0).rgb);
	halo += focus_signal(textureLod(screen_texture, clamp(SCREEN_UV - vec2(0.0, px.y), vec2(0.0), vec2(1.0)), 0.0).rgb);
	halo *= 0.25;

	vec3 focus_boost = source * (1.0 + 0.18 * ink) + vec3(0.08, 0.17, 0.24) * halo * ink;
	float local_restore = clamp(local_focus * focus_restore_strength * (0.48 + 0.52 * ink), 0.0, 0.92);
	local_restore = max(local_restore, recover_mask * (0.26 + 0.42 * focus_restore_strength));
	washed = mix(washed, focus_boost, local_restore);
	washed += vec3(0.58, 0.78, 1.0) * halo * 0.075 * ink;
	washed += vec3(0.94, 0.98, 1.0) * entry_ring * (0.13 + 0.16 * ink);
	washed -= vec3(0.06, 0.08, 0.1) * smoothstep(0.05, 0.42, pulse_distance) * pulse * 0.08;
	washed = mix(washed, source * vec3(0.94, 0.98, 1.06), recover_mask * 0.42);
	washed += vec3(0.18, 0.32, 0.5) * corridor_mask * recover_progress * 0.22;
	washed += vec3(0.26, 0.48, 0.78) * corridor_flow * recover_progress * 0.16;

	float effect_mix = clamp(ink * 0.96 + pulse * 0.18, 0.0, 1.0);
	vec3 final_rgb = mix(source, washed, effect_mix);
	COLOR = vec4(clamp(final_rgb, vec3(0.0), vec3(1.25)), scene.a);
}
