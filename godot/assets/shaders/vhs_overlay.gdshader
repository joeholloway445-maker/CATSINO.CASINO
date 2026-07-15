shader_type canvas_item;
// Mild VHS / tape-glitch overlay for Periliminal pulls.
// Pure canvas_item — safe on gl_compatibility and Web.
// Augment RealityBendOverlay; do not replace reality_bend.gdshader.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float noise_amount : hint_range(0.0, 0.5) = 0.08;
uniform float chroma_offset : hint_range(0.0, 0.01) = 0.0025;
uniform float tracking_warp : hint_range(0.0, 0.05) = 0.012;
uniform float time_scale : hint_range(0.1, 4.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float t = TIME * time_scale;
	vec2 uv = SCREEN_UV;

	float band = step(0.92, hash(vec2(floor(uv.y * 40.0), floor(t * 6.0))));
	uv.x += band * (hash(vec2(t, uv.y)) - 0.5) * tracking_warp;

	float r = texture(screen_texture, uv + vec2(chroma_offset, 0.0)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(chroma_offset, 0.0)).b;
	vec3 col = vec3(r, g, b);

	float n = hash(uv * vec2(800.0, 600.0) + t) - 0.5;
	col += n * noise_amount;

	COLOR = vec4(col, 1.0);
}
