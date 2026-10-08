shader_type canvas_item;
// Viñeta: oscurece suavemente los bordes de la pantalla para centrar la mirada.

uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform vec3 tint : source_color = vec3(0.0, 0.0, 0.03);

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= 1.3;
	float amount = smoothstep(0.38, 0.95, length(uv));
	COLOR = vec4(tint, amount * strength);
}
