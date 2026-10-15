shader_type canvas_item;
// Ropa propia para mamá y papá sobre un sprite provisional de NPC: la camisa clara pasa a shirt_color y
// el pantalón azul oscuro a pants_color, conservando las luces y sombras. La piel, el pelo y los
// contornos quedan igual.

uniform vec4 shirt_color : source_color = vec4(0.54, 0.29, 0.42, 1.0);
uniform vec4 pants_color : source_color = vec4(0.23, 0.23, 0.28, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float maxc = max(c.r, max(c.g, c.b));
	float minc = min(c.r, min(c.g, c.b));
	float sat = maxc > 0.0 ? (maxc - minc) / maxc : 0.0;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 result = c.rgb;
	// Camisa: claro y poco saturado (blanco, gris claro, rosado pálido).
	if (lum > 0.62 && sat < 0.28) {
		result = shirt_color.rgb * (0.55 + lum * 0.6);
	}
	// Pantalón: azul oscuro (más azul que rojo y no muy claro).
	else if (c.b > c.r + 0.06 && lum < 0.42 && lum > 0.06) {
		result = pants_color.rgb * (0.6 + lum * 1.6);
	}
	COLOR = vec4(result, c.a) * COLOR;
}
