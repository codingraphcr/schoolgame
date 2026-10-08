shader_type canvas_item;
// Distorsión de pantalla al acercarse a una amenaza: la "corrupción" afecta lo que ve el jugador.
// strength: 0 = imagen intacta, 1 = distorsión máxima. Lo controla el script según la distancia.

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	if (strength <= 0.001) {
		COLOR = texture(screen_tex, uv);
	} else {
		float t = floor(TIME * 12.0);
		// Franjas horizontales que saltan de lado.
		float band = floor(uv.y * 40.0);
		float jump = step(1.0 - 0.25 * strength, hash(band + t * 7.0));
		uv.x += (hash(band * 3.1 + t) - 0.5) * 0.04 * strength * jump;
		// Separación de canales de color (aberración cromática).
		float split = 0.004 * strength;
		vec4 base = texture(screen_tex, uv);
		float r = texture(screen_tex, uv + vec2(split, 0.0)).r;
		float b = texture(screen_tex, uv - vec2(split, 0.0)).b;
		vec3 color = vec3(r, base.g, b);
		color += vec3(1.0, 0.24, 0.65) * 0.06 * strength * jump;
		// Líneas de barrido.
		color *= 1.0 - 0.08 * strength * step(0.5, fract(SCREEN_UV.y * 180.0));
		COLOR = vec4(color, 1.0);
	}
}
