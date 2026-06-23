shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.5, 0.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	pulse = pulse * 0.3 + 0.7;
	vec4 glow = glow_color * glow_intensity * pulse * base.a;
	COLOR = base + glow * (1.0 - base.a);
	COLOR.a = max(base.a, glow.a * 0.5);
}
