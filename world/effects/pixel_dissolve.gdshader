shader_type canvas_item;
// Kai se deshace en píxeles (y se rearma al reaparecer): cada bloque de píxeles desaparece en un
// momento distinto, con un borde magenta justo antes de irse y un tinte magenta que crece.
// Lo usa KaiVisual.set_dissolve() durante la muerte (DeathSequence).

// 0 = entero, 1 = desaparecido.
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.24, 0.85, 1.0);
uniform float edge_width = 0.14;
// Tamaño de los bloques que se van (en píxeles de la textura).
uniform float block = 2.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 cell = floor(UV / TEXTURE_PIXEL_SIZE / block);
	float noise = hash(cell);
	float t = amount * (1.0 + edge_width);
	if (noise < t - edge_width) {
		color.a = 0.0;
	} else if (noise < t) {
		color.rgb = edge_color.rgb;
	} else {
		color.rgb = mix(color.rgb, edge_color.rgb, amount * 0.45);
	}
	COLOR = color * COLOR;
}
