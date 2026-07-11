shader_type canvas_item;
// CRT-style overlay for Periliminal / Liminal mood.
// Pure canvas_item — safe on gl_compatibility and Web.
// Layer via a ColorRect sibling to RealityBendOverlay;
// do not replace reality_bend.gdshader.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_density : hint_range(100.0, 1200.0) = 480.0;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.85;
uniform float curvature : hint_range(0.0, 0.4) = 0.08;
uniform float brightness : hint_range(0.5, 1.5) = 1.05;

vec2 curve_uv(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) * curvature;
	uv += uv * offset * offset;
	return uv * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(SCREEN_UV);
	vec4 col = texture(screen_texture, uv);

	float scan = sin(uv.y * scanline_density * 3.14159) * 0.5 + 0.5;
	col.rgb *= mix(1.0, scan, scanline_strength);

	vec2 vc = uv * 2.0 - 1.0;
	float vig = 1.0 - dot(vc, vc) * vignette_strength * 0.35;
	col.rgb *= clamp(vig, 0.0, 1.0) * brightness;

	COLOR = col;
}
