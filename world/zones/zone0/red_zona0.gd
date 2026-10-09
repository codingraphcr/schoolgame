extends VectorCanvas
## La red del Pasillo + Laboratorio tal como se ve con la Visión Digital (dibujo vectorial de Ariel):
## cuadrícula, contornos de los objetos, cobertura del Wi-Fi, enlaces a los servidores con paquetes,
## el puente de datos con su fragmento oculto y la forma real del phishing: un pez abisal que usa
## el "correo raro" como carnada. Las posiciones se ajustan en el Inspector.

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const MAG_D := Color("9c1f6e")
const PAPER := Color("e9dfc6")
const ABYSS := Color(0.2, 0.01, 0.12, 0.85)

@export var player: Node2D
## La carnada física (el sobre que cuelga del techo); la antena del pez termina en ella.
@export var lure: Node2D
## Zona de la cuadrícula: entre el techo y el suelo.
@export var area := Rect2(0, 48, 960, 256)
@export var router := Vector2(353, 152)
@export var racks: Array[Vector2] = [Vector2(714, 236), Vector2(744, 236)]
@export var fish_center := Vector2(905, 150)
## Debe coincidir con la colisión del nodo DataBridge.
@export var data_bridge := Rect2(556, 148, 112, 6)
@export var fragment_position := Vector2(640, 126)
## Marca de GameState: si ya se recogió, el fragmento no se dibuja.
@export var fragment_flag: StringName = &"zona0_fragmento_recogido"
@export var platforms: Array[Rect2] = [Rect2(456, 256, 64, 8), Rect2(536, 216, 80, 8), Rect2(632, 252, 40, 8)]
## Objetos físicos que se ven como contornos tenues (casilleros, ventanas, puertas…).
@export var outlines: Array[Rect2] = [
	Rect2(24, 264, 80, 40), Rect2(376, 264, 64, 40), Rect2(120, 232, 36, 24),
	Rect2(172, 196, 40, 28), Rect2(284, 196, 40, 28), Rect2(232, 256, 28, 48),
	Rect2(780, 256, 30, 48),
]


func _ready() -> void:
	painter = _paint
	animated = true
	super()


func _paint(c: VectorCanvas, t: float) -> void:
	_paint_grid(c)
	_paint_wireframe(c)
	_paint_network(c, t)
	_paint_bridge(c, t)
	_paint_fish(c, t)
	# Firma digital de Kai.
	if player:
		var feet := player.global_position
		c.draw_set_transform(feet, 0.0, Vector2(1.0, 0.3))
		c.draw_arc(Vector2.ZERO, 12.0 + sin(t * 4.0) * 1.5, 0.0, TAU, 24, Color(CYAN, 0.7), 1.0, true)
		c.draw_set_transform(Vector2.ZERO)
		c.crisp_text(feet + Vector2(-40, -44), "KAI · ESTUDIANTE", 5, Color(CYAN, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 80)


func _paint_grid(c: VectorCanvas) -> void:
	for x in range(int(area.position.x), int(area.end.x) + 1, 32):
		c.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), Color(CYAN, 0.07), 0.5)
	for y in range(int(area.position.y), int(area.end.y) + 1, 32):
		c.draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(CYAN, 0.07), 0.5)


## Los objetos físicos se ven como contornos tenues: en la red solo importan sus datos.
func _paint_wireframe(c: VectorCanvas) -> void:
	c.draw_line(Vector2(area.position.x, area.end.y), Vector2(area.end.x, area.end.y), Color(CYAN, 0.8), 1.2, true)
	for rect in platforms:
		c.draw_rect(rect, Color(CYAN, 0.5), false, 0.8)
	for rect in outlines:
		c.draw_rect(rect, Color(CYAN, 0.22), false, 0.6)


func _paint_network(c: VectorCanvas, t: float) -> void:
	# Cobertura del Wi-Fi: un anillo grande que late.
	for i in 18:
		var a := i * TAU / 18.0
		c.draw_arc(router, 150.0, a, a + TAU / 36.0, 4, Color(CYAN, 0.25), 0.8, true)
	var ring := fmod(t * 60.0, 150.0)
	c.draw_arc(router, ring, 0.0, TAU, 48, Color(CYAN, 0.25 * (1.0 - ring / 150.0)), 1.0, true)
	# Enlaces del router a los servidores, con paquetes viajando.
	for k in racks.size():
		var link := _link(router, racks[k], -60.0 - k * 20.0)
		c.draw_polyline(link, Color(CYAN, 0.55), 1.0, true)
		for p in 3:
			var point := _point_on(link, fmod(t * 0.35 + p / 3.0 + k * 0.15, 1.0))
			c.glow(point, 4.0, Color(CYAN, 0.7), 4)
			c.draw_circle(point, 0.9, Color.WHITE)
	_node(c, router, "ROUTER WI-FI", CYAN, t)
	for k in racks.size():
		_node(c, racks[k], "SRV-0%d" % (k + 1), CYAN, t + k)


func _paint_bridge(c: VectorCanvas, t: float) -> void:
	var r := data_bridge
	c.glow(r.get_center(), 40.0, Color(CYAN, 0.18))
	c.draw_colored_polygon(VectorCanvas.rounded_rect(r, 2.0), Color(CYAN, 0.35))
	var border := VectorCanvas.rounded_rect(r, 2.0)
	border.append(border[0])
	c.draw_polyline(border, CYAN, 1.0, true)
	for i in 6:
		var x := r.position.x + fmod(t * 30.0 + i * 20.0, r.size.x)
		c.draw_polyline(PackedVector2Array([Vector2(x - 2, r.position.y + 1), Vector2(x, r.get_center().y), Vector2(x - 2, r.end.y - 1)]),
			Color.WHITE, 0.6, true)
	c.crisp_text(Vector2(r.position.x, r.position.y - 3), "PUENTE DE DATOS", 5, Color(CYAN, 0.9), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if not _fragment_taken():
		var p := fragment_position + Vector2(0, sin(t * 2.5) * 2.0)
		c.glow(p, 14.0, Color(CYAN, 0.5))
		c.draw_set_transform(p, t * 1.5)
		c.shape(PackedVector2Array([Vector2(0, -6), Vector2(4, 0), Vector2(0, 6), Vector2(-4, 0)]), Color(CYAN, 0.8), Color.WHITE, 0.7)
		c.draw_set_transform(Vector2.ZERO)


## La forma real de la amenaza: un pez abisal que usa el correo falso como carnada.
func _paint_fish(c: VectorCanvas, t: float) -> void:
	var center := fish_center + Vector2(0, sin(t * 1.2) * 3.0)
	var lure_tip := lure.global_position + Vector2(0, -16) if lure else fish_center + Vector2(-40, 86)
	# Enlace infectado: el pez roba datos del servidor (los paquetes van hacia él).
	if not racks.is_empty():
		var stolen := _link(racks[racks.size() - 1], center + Vector2(-40, 10), 30.0)
		c.draw_polyline(stolen, Color(MAG, 0.7), 1.0, true)
		for p in 4:
			var point := _point_on(stolen, fmod(t * 0.5 + p / 4.0, 1.0))
			c.glow(point, 4.0, Color(MAG, 0.7), 4)
	# Antena con la carnada.
	var head := center + Vector2(-34, -24)
	c.draw_polyline(VectorCanvas.sag_curve(head, lure_tip, -30.0, 20), Color(MAG, 0.9), 1.4, true)
	c.glow(lure_tip, 18.0, Color(MAG, 0.45))
	# Cuerpo.
	c.glow(center, 90.0, Color(MAG, 0.12), 8)
	var body := PackedVector2Array()
	for i in 40:
		var a := i * TAU / 40.0
		var radius := Vector2(56, 40) * (1.0 + 0.04 * sin(a * 5.0 + t * 2.0))
		body.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	c.shape(body, ABYSS, MAG, 1.4)
	# Aletas dorsales.
	for i in 3:
		var base := center + Vector2(-8 + i * 16, -38)
		c.shape(PackedVector2Array([base, base + Vector2(10, -16 - sin(t * 3.0 + i) * 3.0), base + Vector2(14, 2)]), ABYSS, MAG, 1.0)
	# Boca con dientes (se abre y se cierra despacio).
	var open := 6.0 + sin(t * 1.5) * 4.0
	var jaw := PackedVector2Array([center + Vector2(-56, 6), center + Vector2(-20, 6 - open), center + Vector2(-20, 6 + open)])
	c.shape(jaw, Color(0.05, 0.0, 0.03), MAG, 1.0)
	for i in 5:
		var x := -52.0 + i * 7.0
		var top := center + Vector2(x, 6 - open * (x + 56.0) / 36.0)
		var bottom := center + Vector2(x, 6 + open * (x + 56.0) / 36.0)
		c.draw_colored_polygon(PackedVector2Array([top, top + Vector2(3, 0), top + Vector2(1.5, 4)]), PAPER)
		c.draw_colored_polygon(PackedVector2Array([bottom, bottom + Vector2(3, 0), bottom + Vector2(1.5, -4)]), PAPER)
	# Ojo que sigue al jugador.
	var eye := center + Vector2(-22, -14)
	c.glow(eye, 12.0, Color(MAG, 0.6))
	c.draw_circle(eye, 6.0, Color(1.0, 0.85, 0.95))
	var look := (player.global_position + Vector2(0, -16) - eye).normalized() if player else Vector2.LEFT
	c.draw_circle(eye + look * 2.5, 3.0, Color(0.1, 0.0, 0.06))
	# Circuitos corruptos dentro del cuerpo.
	for i in 3:
		var y := center.y - 6 + i * 10
		c.draw_polyline(PackedVector2Array([Vector2(center.x - 4, y), Vector2(center.x + 12, y), Vector2(center.x + 18, y + 6), Vector2(center.x + 40, y + 6)]),
			Color(MAG_D, 0.9), 0.8, true)
	c.crisp_text(center + Vector2(-60, -54), "AMENAZA · PHISHING", 6, MAG, HORIZONTAL_ALIGNMENT_CENTER, 120)


func _node(c: VectorCanvas, pos: Vector2, label: String, color: Color, t: float) -> void:
	c.glow(pos, 16.0, Color(color, 0.35))
	var hexagon := PackedVector2Array()
	for i in 6:
		hexagon.append(pos + Vector2.from_angle(i * TAU / 6.0 + t * 0.3) * 6.0)
	c.shape(hexagon, Color(color, 0.3), color, 1.0)
	c.draw_circle(pos, 1.6, Color.WHITE)
	c.crisp_text(pos + Vector2(-30, -10), label, 5, Color(color, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 60)


func _link(from: Vector2, to: Vector2, bend: float) -> PackedVector2Array:
	return VectorCanvas.sag_curve(from, to, bend * 0.5, 24)


func _point_on(path: PackedVector2Array, u: float) -> Vector2:
	var index := clampf(u, 0.0, 1.0) * (path.size() - 1)
	var i := mini(int(index), path.size() - 2)
	return path[i].lerp(path[i + 1], index - i)


func _fragment_taken() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return game_state != null and game_state.has_flag(fragment_flag)
