shader_type canvas_item;
// Oscurece la pantalla (violeta muy oscuro) dejando un foco de luz suave alrededor de un punto.
// Lo usa NullbladeReveal para la escena de la Nullblade.

uniform vec4 tint : source_color = vec4(0.043, 0.024, 0.094, 1.0);
// Centro del foco y radios en píxeles de la pantalla.
uniform vec2 center = vec2(640.0, 360.0);
uniform float radius = 90.0;
uniform float softness = 160.0;
// 0 = sin oscurecer, 1 = oscuro del todo (fuera del foco).
uniform float strength = 0.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float d = distance(local_pos, center);
	float outside = smoothstep(radius, radius + softness, d);
	COLOR = vec4(tint.rgb, strength * mix(0.55, 1.0, outside));
}
