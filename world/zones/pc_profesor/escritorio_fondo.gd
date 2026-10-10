extends VectorCanvas
## Fondo del escritorio de la computadora del profesor, visto desde dentro por el alma digital de
## Kai (concepto de Ariel en docs/arte/referencias/escritorio_entidad_concepto.webp): una pantalla
## clara invadida por la entidad: columnas de binario que caen y cambian, código hex, terminales
## que se escriben solas, paneles de análisis y circuitos, todo en rosa. Los íconos del escritorio
## están corruptos (glitch). La barra de tareas es el suelo. El ojo de la entidad es EntityEye.
## Solo se dibuja lo que está en pantalla (el nivel mide 3360 px).

const PINK := Color("ff3ea5")
const PINK_SOFT := Color("e46aa8")
const INK := Color("b8306f")
const PAPER_TOP := Color("fdf5fa")
const PAPER_BOTTOM := Color("f6e2ee")
const CYAN := Color("3ef2ff")
## Ancho de cada "bloque" de decoración que se repite a lo largo del nivel.
const TILE := 640.0

## Textos de las terminales (se escriben solas y vuelven a empezar).
const TERMINALS := [
	["> CONNECT...", "> TRACE...", "> MONITOR...", "> LOG...", "> COMPLETE."],
	["> SPAM_DETECTED", "> ISOLATING...", "> BLOCKING...", "> DONE."],
	["  /root", "  /home/kai", "  /system", "> /firewall", "  /spam"],
	["SCAN //", "USER: KAI", "SYS: NULLVEIL", "STATUS: OBSERVADO"],
]
const ICONS := ["Mis documentos", "Correo", "Navegador", "Papelera"]

@export var area := Rect2(0, 0, 960, 360)
@export var floor_y := 304.0
## Mensaje mientras el nivel está en construcción (vacío = ninguno).
@export var construction_note := ""

var _mono: SystemFont


func _ready() -> void:
	painter = _paint
	animated = true
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	super()


func _paint(c: VectorCanvas, t: float) -> void:
	var view := _visible_rect().intersection(area)
	if view.size.x <= 0.0:
		return
	c.gradient_rect(Rect2(view.position.x, area.position.y, view.size.x, floor_y - area.position.y), PAPER_TOP, PAPER_BOTTOM)
	# Cuadrícula de la pantalla.
	var x0 := floorf(view.position.x / 24.0) * 24.0
	for x in range(int(x0), int(view.end.x) + 24, 24):
		c.draw_line(Vector2(x, area.position.y), Vector2(x, floor_y), Color(PINK, 0.06), 0.5)
	for y in range(int(area.position.y), int(floor_y), 24):
		c.draw_line(Vector2(view.position.x, y), Vector2(view.end.x, y), Color(PINK, 0.04), 0.5)
	# Decoración por bloques (siempre igual en el mismo lugar; animada con el tiempo).
	var first := int(floor(view.position.x / TILE)) - 1
	var last := int(floor(view.end.x / TILE)) + 1
	for i in range(first, last + 1):
		_paint_tile(c, i, t)
	_paint_icons(c, t)
	_paint_taskbar(c, view)
	if not construction_note.is_empty():
		c.crisp_text(Vector2(area.get_center().x - 160, 250), construction_note, 7, Color(PINK, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 320)


## Rectángulo del mundo que se ve en pantalla (con un margen).
func _visible_rect() -> Rect2:
	var inverse := get_canvas_transform().affine_inverse()
	return (inverse * get_viewport_rect()).grow(40.0)


func _paint_tile(c: VectorCanvas, index: int, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(index * 7919 + 13)
	var x := index * TILE
	if x + TILE < area.position.x or x > area.end.x:
		return
	# Circuitos con nodos cuadrados.
	for k in 3:
		var y := rng.randf_range(20.0, floor_y - 40.0)
		var start := Vector2(x + rng.randf_range(0.0, TILE * 0.6), y)
		var mid := start + Vector2(rng.randf_range(40.0, 120.0), 0)
		var end := mid + Vector2(0, rng.randf_range(-40.0, 40.0))
		var tail := end + Vector2(rng.randf_range(30.0, 90.0), 0)
		c.draw_polyline(PackedVector2Array([start, mid, end, tail]), Color(PINK, 0.18), 1.0)
		c.draw_rect(Rect2(tail - Vector2(2, 2), Vector2(4, 4)), Color(PINK, 0.35), false, 1.0)
		# Un pulso que viaja por el circuito.
		var p := fmod(t * 0.35 + k * 0.33 + index * 0.17, 1.0)
		c.draw_rect(Rect2(start.lerp(mid, p) - Vector2(1, 1), Vector2(2, 2)), Color(PINK, 0.6))
	# Columnas de binario que caen y cambian.
	for k in 2:
		var cx := x + rng.randf_range(80.0, TILE - 120.0)
		var speed := rng.randf_range(6.0, 14.0)
		var rows := 11
		var scroll := fmod(t * speed, rows * 11.0)
		for r in rows:
			var y := fmod(r * 11.0 + scroll, rows * 11.0) + 18.0
			var seed := int(t * 2.0) + r * 31 + k * 101 + index * 7
			_code(c, Vector2(cx, y), _binary(seed), 6, Color(PINK_SOFT, 0.35 + 0.15 * float(r % 3 == 0)))
	# Código hex que cambia.
	var hx := Vector2(x + rng.randf_range(20.0, TILE - 200.0), rng.randf_range(36.0, 160.0))
	for r in 4:
		_code(c, hx + Vector2(0, r * 11.0), _hex(int(t * 1.5) + r * 17 + index * 5), 6, Color(PINK_SOFT, 0.4))
	# Terminal que se escribe sola.
	var lines: Array = TERMINALS[posmod(index, TERMINALS.size())]
	var box := Rect2(x + rng.randf_range(260.0, TILE - 150.0), rng.randf_range(40.0, 150.0), 120, 14 + lines.size() * 11)
	c.draw_rect(box, Color(1, 1, 1, 0.35))
	c.draw_rect(box, Color(PINK, 0.3), false, 1.0)
	var cycle := fmod(t * 0.6 + index, lines.size() + 3.0)
	for r in lines.size():
		if r < cycle:
			_code(c, box.position + Vector2(8, 13 + r * 11), lines[r], 6, Color(INK, 0.45))
	if fmod(t, 1.0) < 0.5:
		var shown := mini(int(cycle), lines.size())
		c.draw_rect(Rect2(box.position + Vector2(8, 6 + shown * 11), Vector2(4, 7)), Color(PINK, 0.6))
	# Panel "ANALIZANDO" con su barra.
	var panel := Rect2(x + rng.randf_range(40.0, TILE - 170.0), rng.randf_range(170.0, 230.0), 110, 30)
	c.draw_rect(panel, Color(1, 1, 1, 0.45))
	c.draw_rect(panel, Color(PINK, 0.35), false, 1.0)
	_code(c, panel.position + Vector2(7, 11), "ANALIZANDO.", 5, Color(INK, 0.6))
	var bar := Rect2(panel.position + Vector2(7, 17), Vector2(96, 4))
	c.draw_rect(bar, Color(PINK, 0.15))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fmod(t * 0.25 + index * 0.3, 1.0), bar.size.y)), Color(PINK, 0.6))
	# Cuadritos huecos que flotan.
	for k in 6:
		var base := Vector2(x + rng.randf_range(0.0, TILE), rng.randf_range(16.0, floor_y - 20.0))
		var drift := Vector2(sin(t * 0.7 + k), cos(t * 0.5 + k * 2.0)) * 3.0
		var s := float(rng.randi_range(3, 6))
		c.draw_rect(Rect2(base + drift, Vector2(s, s)), Color(PINK, 0.3), false, 1.0)


## Íconos del escritorio corruptos: se separan en colores, se cortan en franjas y el nombre se
## daña de vez en cuando.
func _paint_icons(c: VectorCanvas, t: float) -> void:
	var reduced := GameSettings.reduce_glitch
	for i in ICONS.size():
		var pos := Vector2(40, 84 + i * 43)
		var rect := Rect2(pos, Vector2(22, 18))
		var glitch := fmod(t * (0.9 + i * 0.13) + i * 0.37, 1.0) < (0.08 if reduced else 0.22)
		if glitch and not reduced:
			c.draw_rect(Rect2(rect.position + Vector2(-2, 0), rect.size), Color(PINK, 0.55))
			c.draw_rect(Rect2(rect.position + Vector2(2, 0), rect.size), Color(CYAN, 0.45))
		c.gradient_box(rect, 3.0, Color("3a6fc4"), Color("234a8a"), Color(PINK, 0.6), 0.8)
		if glitch:
			# Franjas desplazadas y ruido.
			for s in 3:
				var y := rect.position.y + randf_range(0.0, rect.size.y - 3.0)
				var shift := randf_range(-5.0, 5.0)
				c.draw_rect(Rect2(rect.position.x + shift, y, rect.size.x, randf_range(1.0, 3.0)), [PINK, Color("234a8a"), Color.WHITE].pick_random())
			for n in 5:
				c.draw_rect(Rect2(rect.position + Vector2(randf() * rect.size.x, randf() * rect.size.y), Vector2.ONE * 2.0), Color(PINK, 0.8))
		var label: String = ICONS[i]
		if glitch:
			label = _corrupt(label, int(t * 12.0) + i)
		c.crisp_text(pos + Vector2(-20, 30), label, 5, Color("2a1630", 0.85), HORIZONTAL_ALIGNMENT_CENTER, 62)


## Barra de tareas (el suelo).
func _paint_taskbar(c: VectorCanvas, view: Rect2) -> void:
	c.draw_rect(Rect2(view.position.x, floor_y, view.size.x, area.end.y - floor_y), Color("f3e4ee"))
	c.draw_line(Vector2(view.position.x, floor_y), Vector2(view.end.x, floor_y), Color(PINK, 0.9), 1.5, true)
	if view.position.x < 60.0:
		c.gradient_box(Rect2(8, floor_y + 6, 40, 16), 3.0, Color("2d8fd4"), Color("1b5c99"), Color(PINK, 0.5), 0.8)
		c.crisp_text(Vector2(8, floor_y + 18), "Inicio", 5, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 40)


## Texto monoespaciado nítido (con la cámara ×2).
func _code(c: VectorCanvas, pos: Vector2, text: String, size: int, color: Color) -> void:
	c.draw_set_transform(pos, 0.0, Vector2(0.5, 0.5))
	c.draw_string(_mono, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size * 2, color)
	c.draw_set_transform(Vector2.ZERO)


static func _binary(seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var s := ""
	for i in 9:
		s += "1" if rng.randf() < 0.4 else "0"
	return s


static func _hex(seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var parts := []
	for i in 5:
		parts.append("0x%02X" % rng.randi_range(0, 255))
	return " ".join(parts)


## Cambia algunas letras por símbolos (texto dañado).
static func _corrupt(text: String, seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var symbols := "#%&@!?01/"
	var out := ""
	for ch in text:
		out += symbols[rng.randi() % symbols.length()] if ch != " " and rng.randf() < 0.3 else ch
	return out
