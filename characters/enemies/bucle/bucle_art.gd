class_name BucleArt
extends RefCounted
## Dibujo provisional de Bucle por código (hasta que Ariel lo dibuje). El cuerpo es siempre del mismo
## tamaño; lo que crece con cada etapa (1 a 7) es la acumulación de instrucciones a su alrededor:
## 1 Inocencia (un anillo, cálido, alegre) · 2 Repetición (dos anillos, confiado) · 3 Acumulación (código,
## cansado) · 4 Sobrecarga (anillos encimados, confundido) · 5 Corrupción (interferencias, asustado) ·
## 6 Descontrol (muchas instrucciones) · 7 Último ciclo (máxima acumulación, agotado).
## El cuerpo se dibuja al final, con contorno: su posición real siempre se distingue.

const BODY_RADIUS := 11.0
const CENTER := Vector2(0, -14)
const WARM := Color("ffcf5c")
const HOT := Color("ff7a5c")
const COLD := Color("b48cff")
const OUTLINE := Color("1a0f08")
const CODE: PackedStringArray = ["repetir()", "i = i + 1", "mientras", "otra vez", "tarea()", "error", "¿fin?", "loop"]
## Expresión de cada etapa.
const MOODS: Array[StringName] = [&"alegre", &"confiado", &"cansado", &"confundido", &"asustado", &"asustado", &"agotado"]


static func body_color(stage: int) -> Color:
	var t := clampf((stage - 1) / 6.0, 0.0, 1.0)
	return WARM.lerp(HOT, minf(t * 2.0, 1.0)).lerp(COLD, maxf(t * 2.0 - 1.0, 0.0))


## mood: vacío = el de la etapa; &"golpe", &"preparando", &"cansado", &"libre" según el estado.
static func draw(c: CanvasItem, stage: int, clock: float, mood: StringName, glitch: float) -> void:
	var color := body_color(stage)
	_draw_rings(c, stage, clock, color)
	if stage >= 3:
		_draw_code(c, stage, clock, color)
	if stage >= 5 and glitch > 0.0:
		_draw_interference(c, stage, clock, glitch)
	_draw_body(c, stage, clock, mood if mood != &"" else MOODS[clampi(stage - 1, 0, 6)], color)


static func _draw_rings(c: CanvasItem, stage: int, clock: float, color: Color) -> void:
	for i in stage:
		var radius := 17.0 + i * (4.0 if stage >= 4 else 6.0)
		var turn := clock * (1.0 + i * 0.35) * (1.0 if i % 2 == 0 else -1.0)
		var alpha := 0.75 - i * 0.06
		c.draw_arc(CENTER, radius, turn, turn + TAU * 0.8, 32, Color(color, alpha), 1.5)
		# Un «paso» del ciclo que gira: un puntito en la punta del arco.
		c.draw_circle(CENTER + Vector2.from_angle(turn + TAU * 0.8) * radius, 1.6, Color(Color.WHITE, alpha))


static func _draw_code(c: CanvasItem, stage: int, clock: float, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var count := (stage - 2) * 3
	for i in count:
		var radius := 30.0 + (i % 4) * 8.0 + stage * 2.0
		var angle := clock * (0.6 + (i % 3) * 0.25) + i * TAU / count
		var at := CENTER + Vector2.from_angle(angle) * Vector2(radius * 1.3, radius * 0.8)
		var text := CODE[i % CODE.size()]
		if stage >= 7 and i % 2 == 0:
			text = text.substr(0, maxi(2, int(text.length() / 2.0)))  # Instrucciones fragmentadas.
		c.draw_string(font, at - Vector2(text.length() * 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(color, 0.55))


static func _draw_interference(c: CanvasItem, stage: int, clock: float, glitch: float) -> void:
	var lines := int((stage - 4) * 3 * glitch)
	for i in lines:
		var hashed := sin(clock * 7.3 + i * 12.9) * 43758.5
		var noise := hashed - floorf(hashed)
		var y := CENTER.y - 40.0 + noise * 70.0
		var shift := (noise - 0.5) * 30.0 * glitch
		c.draw_line(Vector2(-50 + shift, y), Vector2(50 + shift, y), Color(Color("ff3ea5"), 0.25 * glitch), 1.0)


static func _draw_body(c: CanvasItem, stage: int, clock: float, mood: StringName, color: Color) -> void:
	var bob := sin(clock * (3.0 + stage * 0.3)) * 1.5
	var center := CENTER + Vector2(0, bob)
	c.draw_circle(center, BODY_RADIUS + 1.5, OUTLINE)
	c.draw_circle(center, BODY_RADIUS, color)
	c.draw_circle(center + Vector2(-3, -4), 3.0, Color(1, 1, 1, 0.35))
	c.draw_arc(center, BODY_RADIUS + 2.5, 0.0, TAU, 24, Color(Color.WHITE, 0.6), 1.0)
	# Una antena en forma de flecha de ciclo.
	c.draw_arc(center + Vector2(0, -BODY_RADIUS - 4.0), 3.0, PI * 0.2, PI * 1.6, 8, OUTLINE, 1.5)
	var dark := OUTLINE
	match mood:
		&"alegre", &"libre":
			for side in [-1.0, 1.0]:
				c.draw_arc(center + Vector2(side * 4.0, -1.0), 2.0, PI, TAU, 6, dark, 1.5)
			c.draw_arc(center + Vector2(0, 3.0), 3.5, 0.2, PI - 0.2, 8, dark, 1.5)
		&"confiado":
			for side in [-1.0, 1.0]:
				c.draw_line(center + Vector2(side * 2.0, -2.0), center + Vector2(side * 6.0, -1.0), dark, 1.5)
			c.draw_arc(center + Vector2(1.0, 3.0), 3.0, 0.1, PI * 0.8, 8, dark, 1.5)
		&"cansado":
			for side in [-1.0, 1.0]:
				c.draw_line(center + Vector2(side * 2.5, -0.5), center + Vector2(side * 6.0, -0.5), dark, 1.5)
			c.draw_line(center + Vector2(-2.5, 4.0), center + Vector2(2.5, 4.0), dark, 1.5)
			c.draw_circle(center + Vector2(9.0, -6.0 + fmod(clock * 6.0, 6.0)), 1.2, Color("8ad8ff"))
		&"confundido":
			c.draw_circle(center + Vector2(-4.0, -1.0), 2.4, dark)
			c.draw_circle(center + Vector2(4.0, -1.0), 1.2, dark)
			c.draw_polyline(PackedVector2Array([center + Vector2(-3, 4), center + Vector2(-1, 3), center + Vector2(1, 5), center + Vector2(3, 4)]), dark, 1.5)
		&"asustado":
			for side in [-1.0, 1.0]:
				c.draw_circle(center + Vector2(side * 4.0, -1.0), 2.6, Color.WHITE)
				c.draw_circle(center + Vector2(side * 4.0, -1.0), 1.0, dark)
			c.draw_circle(center + Vector2(0, 4.5), 1.8, dark)
		&"agotado":
			for side in [-1.0, 1.0]:
				var eye := center + Vector2(side * 4.0, -1.0)
				c.draw_line(eye + Vector2(-1.5, -1.5), eye + Vector2(1.5, 1.5), dark, 1.2)
				c.draw_line(eye + Vector2(-1.5, 1.5), eye + Vector2(1.5, -1.5), dark, 1.2)
			c.draw_line(center + Vector2(-2.0, 4.5), center + Vector2(2.0, 4.0), dark, 1.2)
		&"golpe":
			for side in [-1.0, 1.0]:
				c.draw_line(center + Vector2(side * 2.0, -3.0), center + Vector2(side * 6.0, 0.0), dark, 1.5)
				c.draw_line(center + Vector2(side * 2.0, 1.0), center + Vector2(side * 6.0, 0.0), dark, 1.5)
			c.draw_circle(center + Vector2(0, 4.5), 2.0, dark)
		_:
			for side in [-1.0, 1.0]:
				c.draw_circle(center + Vector2(side * 4.0, -1.0), 1.6, dark)
