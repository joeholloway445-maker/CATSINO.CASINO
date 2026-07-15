shader_type canvas_item;
// Ordered dither / film-grain overlay for Liminal mood on mobile.
// Pure canvas_item — safe on gl_compatibility and Web.
// Layer with RealityBendOverlay; do not replace reality_bend.gdshader.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.35;
uniform float color_levels : hint_range(2.0, 32.0) = 12.0;
uniform float grain : hint_range(0.0, 0.2) = 0.04;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int index = x + y * 4;
	// 4x4 Bayer matrix values / 16
	if (index == 0) return 0.0;
	if (index == 1) return 0.5;
	if (index == 2) return 0.125;
	if (index == 3) return 0.625;
	if (index == 4) return 0.75;
	if (index == 5) return 0.25;
	if (index == 6) return 0.875;
	if (index == 7) return 0.375;
	if (index == 8) return 0.1875;
	if (index == 9) return 0.6875;
	if (index == 10) return 0.0625;
	if (index == 11) return 0.5625;
	if (index == 12) return 0.9375;
	if (index == 13) return 0.4375;
	if (index == 14) return 0.8125;
	return 0.3125;
}

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	float threshold = bayer4(FRAGCOORD.xy) - 0.5;
	vec3 dithered = col.rgb + threshold * dither_strength / max(color_levels, 1.0);
	dithered = floor(dithered * color_levels + 0.5) / max(color_levels, 1.0);
	float n = fract(sin(dot(SCREEN_UV * vec2(1200.0, 800.0) + vec2(TIME), vec2(12.9898, 78.233))) * 43758.5453);
	dithered += (n - 0.5) * grain;
	COLOR = vec4(mix(col.rgb, dithered, dither_strength), col.a);
}
