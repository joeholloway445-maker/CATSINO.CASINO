shader_type spatial;
render_mode unshaded, cull_front, blend_add;

uniform vec4 aura_color : source_color = vec4(0.7, 0.0, 1.0, 1.0);
uniform float aura_size : hint_range(0.0, 0.5) = 0.08;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;

void vertex() {
	float pulse = sin(TIME * pulse_speed) * 0.2 + 0.8;
	VERTEX += NORMAL * aura_size * pulse;
}

void fragment() {
	ALBEDO = aura_color.rgb;
	ALPHA = aura_color.a * 0.6;
	EMISSION = aura_color.rgb * 1.5;
}
