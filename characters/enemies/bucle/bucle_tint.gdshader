// Color de Bucle por etapa: los sprites de la hoja de Ariel son amarillos (etapa 1); este shader gira el tono de
// los colores fuertes al color de la etapa (BucleArt.PALETTE), conservando luces y sombras. Lo blanco y lo
// oscuro (la cara) no cambian.
shader_type canvas_item;

uniform vec4 target : source_color = vec4(1.0, 0.8, 0.34, 1.0);
// Tono de la hoja (amarillo anaranjado): ese queda exactamente en target.
uniform float base_hue = 0.11;

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec3 hsv = rgb2hsv(COLOR.rgb);
	float strong = smoothstep(0.2, 0.4, hsv.y);
	float target_hue = rgb2hsv(target.rgb).x;
	float d = hsv.x - base_hue;
	d -= round(d);
	// Todos los tonos van al de la etapa (la hoja cambia de color al cargar un ataque: aquí manda la etapa);
	// queda una pequeña variación para que no sea un solo color plano.
	vec3 shifted = hsv2rgb(vec3(fract(target_hue + clamp(d, -0.12, 0.12) * 0.35), hsv.y, hsv.z));
	COLOR.rgb = mix(COLOR.rgb, shifted, strong);
}
