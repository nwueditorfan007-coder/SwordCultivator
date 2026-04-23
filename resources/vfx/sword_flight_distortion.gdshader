shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float distortion_strength = 0.0024;
uniform float opacity = 0.58;
uniform float flow_speed = 2.2;

void fragment() {
	float mask = texture(TEXTURE, UV).a;
	vec2 local = UV * 2.0 - 1.0;
	vec2 shaped = vec2(local.x * 0.9, local.y * 2.7);
	float radial = clamp(1.0 - length(shaped), 0.0, 1.0);
	float body = pow(radial, 1.25) * mask;
	vec2 screen_px = SCREEN_UV / SCREEN_PIXEL_SIZE;
	float phase = TIME * (1.0 + flow_speed * 0.35);
	float wave_a = sin(screen_px.x * 0.032 + screen_px.y * 0.009 + phase * 1.8);
	float wave_b = cos(screen_px.y * 0.025 - screen_px.x * 0.012 - phase * 1.35);
	float wave_c = sin((screen_px.x + screen_px.y) * 0.016 - phase * 1.15);
	vec2 flow = vec2(wave_b + wave_c * 0.4, wave_a + wave_c * 0.35);
	vec2 lens = vec2(local.x * 0.24, -local.y * 0.68);
	vec2 offset = (flow * 0.72 + lens * 0.28) * distortion_strength * body;
	vec2 sample_uv = clamp(SCREEN_UV + offset, vec2(0.0), vec2(1.0));
	vec4 scene = textureLod(screen_texture, sample_uv, 0.0);
	COLOR = vec4(scene.rgb, clamp(body * opacity, 0.0, 1.0));
}
