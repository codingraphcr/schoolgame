shader_type canvas_item;
// Funde los cuatro bordes de una imagen con lo que hay detrás (el arte trae su fondo oscuro).

uniform float fade : hint_range(0.0, 0.5) = 0.14;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	color.a *= smoothstep(0.0, fade, edge);
	COLOR = color * COLOR;
}
