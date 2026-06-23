shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform vec4 base_color : source_color = vec4(0.0, 0.8, 1.0, 0.6);
uniform float scan_speed : hint_range(0.1, 5.0) = 1.0;
uniform float scan_frequency : hint_range(1.0, 50.0) = 20.0;
uniform float flicker_speed : hint_range(0.0, 20.0) = 8.0;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;

void fragment() {
	float scan = sin(FRAGCOORD.y * scan_frequency * 0.1 + TIME * scan_speed) * 0.5 + 0.5;
	float flicker = sin(TIME * flicker_speed) * 0.05 + 0.95;
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), rim_power);

	vec3 color = base_color.rgb + vec3(rim * 0.3);
	float alpha = base_color.a * (0.7 + scan * 0.3) * flicker + rim * 0.4;

	ALBEDO = color;
	ALPHA = clamp(alpha, 0.0, 1.0);
	EMISSION = color * 0.5 * flicker;
}
