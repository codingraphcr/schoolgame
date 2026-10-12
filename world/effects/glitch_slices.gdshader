shader_type canvas_item;
// Glitch de "ventanas inestables": algunas franjas horizontales del sprite se corren unos píxeles
// de golpe y se tiñen de magenta. Lo usa el jefe «Contraseña débil» en su fase 2.

// 0 = sin glitch, 1 = glitch completo.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.24, 0.62, 1.0);

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float slice = floor(UV.y / TEXTURE_PIXEL_SIZE.y / 6.0);
	float step_time = floor(TIME * 10.0);
	float chance = hash(slice * 1.7 + step_time * 7.13);
	float shift = 0.0;
	if (chance > 1.0 - 0.18 * intensity) {
		shift = (hash(slice * 3.1 + step_time) - 0.5) * 14.0 * intensity;
	}
	uv.x += shift * TEXTURE_PIXEL_SIZE.x;
	vec4 color = texture(TEXTURE, uv);
	if (shift != 0.0) {
		color.rgb = mix(color.rgb, tint.rgb, 0.4);
	}
	COLOR = color * COLOR;
}
