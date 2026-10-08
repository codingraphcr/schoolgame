shader_type canvas_item;
// Convierte un dibujo suavizado en pixel art: transparencia de todo o nada y contorno de 1 píxel.

uniform vec4 outline_color : source_color = vec4(0.03, 0.04, 0.09, 1.0);
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (color.a >= alpha_cut) {
		COLOR = vec4(color.rgb, 1.0);
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float neighbor = max(
			max(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a),
			max(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a));
		COLOR = neighbor >= alpha_cut ? outline_color : vec4(0.0);
	}
}
