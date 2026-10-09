shader_type canvas_item;
// Suaviza los bordes donde el retrato está cortado (sobre todo el que mira al centro de la pantalla).
// El borde que mira hacia el centro de la pantalla se desvanece más; abajo queda sólido
// porque lo tapa la caja de diálogo.

// true si el borde que mira al centro está en UV.x = 1 (depende del lado y de si está volteado).
uniform bool inner_at_uv_one = true;
uniform float inner_fade : hint_range(0.0, 1.0) = 0.14;
uniform float outer_fade : hint_range(0.0, 1.0) = 0.02;
uniform float top_fade : hint_range(0.0, 1.0) = 0.02;
// 1 = hablando; menos = atenuado (el otro personaje habla).
uniform float brightness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float to_inner = inner_at_uv_one ? 1.0 - UV.x : UV.x;
	float to_outer = inner_at_uv_one ? UV.x : 1.0 - UV.x;
	float alpha = smoothstep(0.0, inner_fade, to_inner) * smoothstep(0.0, outer_fade, to_outer) * smoothstep(0.0, top_fade, UV.y);
	COLOR = vec4(color.rgb * brightness, color.a * alpha * COLOR.a);
}
