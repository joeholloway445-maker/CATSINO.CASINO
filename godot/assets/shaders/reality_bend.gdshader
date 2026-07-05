shader_type canvas_item;
// The signature "reality is not stable here" full-screen pass. Chromatic
// split, scanline crawl, a slow non-euclidean UV warp, and a rare hard
// glitch-tear — intensity-driven so it reads as ambient wrongness at low
// values and full Backrooms/Upside-Down at high ones. Applied per-layer
// via RealityBendOverlay; intensity also nudges upward from live psych
// telemetry (Hope's anxiety axis) so the screen itself reacts to dread.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.0, 3.0) = 1.0;
uniform vec4 tint : source_color = vec4(0.55, 0.15, 0.65, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float t = TIME * time_scale;
	vec2 uv = SCREEN_UV;

	// Slow, non-euclidean warp — the space itself breathing wrong.
	vec2 warp = vec2(
		sin(uv.y * 9.0 + t * 0.6) * 0.0035,
		cos(uv.x * 7.0 + t * 0.5) * 0.0035
	) * intensity;

	// Rare hard glitch tear: a thin horizontal band snaps sideways.
	float tear_band = step(0.997, hash(vec2(floor(t * 6.0), 0.0)));
	float band_y = hash(vec2(floor(t * 6.0), 1.0));
	float in_band = step(abs(uv.y - band_y), 0.01) * tear_band;
	warp.x += in_band * (hash(vec2(floor(t * 20.0), 2.0)) - 0.5) * 0.08 * intensity;

	// Chromatic aberration split, scaled by intensity + distance from center
	// (worse at the edges — the middle of your vision is the last to go).
	float edge = length(uv - 0.5) * 1.4;
	float split = (0.0015 + edge * 0.004) * intensity;
	vec3 col;
	col.r = texture(screen_texture, uv + warp + vec2(split, 0.0)).r;
	col.g = texture(screen_texture, uv + warp).g;
	col.b = texture(screen_texture, uv + warp - vec2(split, 0.0)).b;

	// Slow scanline crawl.
	float scan = sin(uv.y * 800.0 - t * 40.0) * 0.02 * intensity;
	col -= scan;

	// A whisper of tint bleeding in at higher intensity — never full color
	// wash, just enough that something feels off.
	col = mix(col, col * tint.rgb + tint.rgb * 0.05, intensity * 0.25);

	// Vignette deepens with intensity.
	float vig = smoothstep(1.05, 0.35, edge) ;
	col *= mix(1.0, vig, intensity * 0.6);

	COLOR = vec4(col, 1.0);
}
