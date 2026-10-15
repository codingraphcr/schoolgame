class_name BucleArt
extends RefCounted
## Dibujo de Bucle. El cuerpo son los sprites de la hoja de Ariel (bucle_sprites.webp →
## tools/art/extraer_personajes_concepto.gd -- bucle → assets/art/characters/bucle/): una animación por estado
## (draw_sprite); el color de cada etapa lo pone bucle_tint.gdshader. Alrededor, la acumulación que crece
## con cada etapa (1 a 7), con la paleta de la hoja: 1 Inocencia (un anillo) · 2 Repetición (dos anillos) ·
## 3 Acumulación (código) · 4 Sobrecarga (anillos encimados) · 5 Corrupción (interferencias) · 6 Descontrol
## (muchas instrucciones) · 7 Último ciclo (máxima acumulación). Sin sprites, el cuerpo provisional por código.
## El cuerpo se dibuja al final: su posición real siempre se distingue.

const BODY_RADIUS := 11.0
const CENTER := Vector2(0, -14)
## Paleta de la hoja de Ariel, una por etapa.
const PALETTE: Array[Color] = [Color("ffcb57"), Color("ff9d3d"), Color("ff6b51"), Color("ff3b6a"), Color("d14bff"),
	Color("a855ff"), Color("6c3bff")]
const OUTLINE := Color("1a0f08")
const CODE: PackedStringArray = ["repetir()", "i = i + 1", "mientras", "otra vez", "tarea()", "error", "¿fin?", "loop"]
## Expresión de cada etapa (cuerpo provisional por código).
const MOODS: Array[StringName] = [&"alegre", &"confiado", &"cansado", &"confundido", &"asustado", &"asustado", &"agotado"]
const SPRITES := "res://assets/art/characters/bucle/"
## Los cuadros se ven a mitad de escala (como Kai); los pies del sprite en el origen.
const SPRITE_SCALE := 0.5

static var _anims: Dictionary = {}


static func body_color(stage: int) -> Color:
	return PALETTE[clampi(stage - 1, 0, PALETTE.size() - 1)]


## Todo junto en un solo CanvasItem (sin el color por etapa del shader): lo de alrededor y el cuerpo.
## mood: vacío = el de la etapa; &"golpe", &"preparando", &"cansado", &"libre" según el estado.
static func draw(c: CanvasItem, stage: int, clock: float, mood: StringName, glitch: float) -> void:
	draw_around(c, stage, clock, glitch)
	if not draw_sprite(c, anim_for_mood(mood), clock, stage, clock):
		draw_fallback(c, stage, clock, mood)


## Lo que rodea a Bucle y crece con cada etapa: anillos de instrucciones (el primero ya lo trae el sprite),
## pseudocódigo desde la etapa 3 e interferencias desde la 5.
static func draw_around(c: CanvasItem, stage: int, clock: float, glitch: float) -> void:
	var color := body_color(stage)
	_draw_rings(c, stage, clock, color)
	if stage >= 3:
		_draw_code(c, stage, clock, color)
	if stage >= 5 and glitch > 0.0:
		_draw_interference(c, stage, clock, glitch)


## La flecha de ciclo sobre la cabeza (con las Copias del proceso): en el verdadero gira como las agujas del
## reloj (direction 1) y en las copias al revés (-1).
static func draw_cycle_arrow(c: CanvasItem, clock: float, direction: float, color: Color) -> void:
	var at := Vector2(0, -68)
	var start := clock * 3.5 * direction
	var sweep := TAU * 0.72 * direction
	c.draw_arc(at, 6.0, start, start + sweep, 16, OUTLINE, 3.5)
	c.draw_arc(at, 6.0, start, start + sweep, 16, color.lightened(0.3), 2.0)
	var end := start + sweep
	var tip := at + Vector2.from_angle(end) * 6.0
	var ahead := Vector2.from_angle(end + PI / 2.0 * direction)
	var side := Vector2.from_angle(end)
	var head := PackedVector2Array([tip + ahead * 4.0, tip - side * 3.5, tip + side * 3.5])
	c.draw_colored_polygon(head, color.lightened(0.3))
	c.draw_polyline(head + PackedVector2Array([head[0]]), OUTLINE, 1.0)


## El cuerpo provisional por código (si no están los sprites).
static func draw_fallback(c: CanvasItem, stage: int, clock: float, mood: StringName) -> void:
	_draw_body(c, stage, clock, mood if mood != &"" else MOODS[clampi(stage - 1, 0, 6)], body_color(stage))


## La animación de la hoja para cada estado de ánimo del cuerpo provisional.
static func anim_for_mood(mood: StringName) -> String:
	match mood:
		&"preparando":
			return "preparar"
		&"cansado":
			return "aturdido"
		&"golpe":
			return "dano"
		&"libre":
			return "derrota"
	return "quieto"


## Un cuadro de la animación anim («quieto», «preparar», «onda», «lluvia», «anillo», «dano», «aturdido»,
## «recarga», «derrota», «desaparicion», «mover») a anim_time segundos de empezar (las que no se repiten quedan
## en su último cuadro). Flota subiendo y bajando, salvo en la derrota. false si no están los sprites.
static func draw_sprite(c: CanvasItem, anim: String, anim_time: float, stage: int, clock: float) -> bool:
	var info := animation("bucle_" + anim)
	if info.is_empty():
		return false
	var size: Vector2 = info.size
	var frame := int(anim_time * float(info.fps))
	frame = frame % int(info.frames) if info.loop else mini(frame, int(info.frames) - 1)
	var bob := 0.0 if anim in ["derrota", "desaparicion"] else sin(clock * (3.0 + stage * 0.3)) * 1.5
	c.draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE * SPRITE_SCALE)
	c.draw_texture_rect_region(info.texture, Rect2(-info.feet, size), Rect2(Vector2(frame * size.x, 0), size))
	c.draw_set_transform(Vector2.ZERO)
	return true


## Datos de una animación (textura, tamaño de cuadro, pies, cuadros, fps). Vacío si no existe.
static func animation(anim_name: String) -> Dictionary:
	if _anims.is_empty():
		var file := FileAccess.open(SPRITES + "bucle.json", FileAccess.READ)
		var data: Dictionary = JSON.parse_string(file.get_as_text()) if file else {}
		for key: String in data.get("animations", {}):
			var entry: Dictionary = data.animations[key]
			_anims[key] = { "texture": load(SPRITES + String(entry.file)), "size": Vector2(entry.frame_size[0], entry.frame_size[1]),
				"feet": Vector2(entry.feet[0], entry.feet[1]), "frames": int(entry.frames), "fps": float(entry.fps),
				"loop": bool(entry.get("loop", true)) }
	return _anims.get(anim_name, {})

static func _draw_rings(c: CanvasItem, stage: int, clock: float, color: Color) -> void:
	for i in stage - 1:  # El primer anillo ya lo trae el sprite.
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
