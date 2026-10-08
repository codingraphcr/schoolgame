extends "res://prototypes/estilos/pixel/muestra_pixel.gd"
## Muestra D: dos mundos.
## El colegio físico es pixel art. Con la Visión Digital (F) el mundo se oscurece y aparece
## la red por dentro en estilo vectorial: conexiones, datos, la cobertura del Wi-Fi y la
## forma real de la amenaza. El "correo raro" era la carnada de un pez abisal: phishing.
## También aparece un puente de datos que solo existe en el mundo digital (en el juego final
## usaría la capa de colisión "mundo_digital" del proyecto).

const GLITCH_SHADER := preload("res://prototypes/estilos/mixta/glitch_cercania.gdshader")
const TRANSITION_TIME := 0.45
const PHYSICAL_AMBIENT := Color(0.62, 0.66, 0.85)
const DIGITAL_AMBIENT := Color(0.13, 0.16, 0.3)
const DATA_BRIDGE := Rect2(556, 148, 112, 6)
const FRAGMENT_POSITION := Vector2(640, 126)
const FISH_CENTER := Vector2(905, 150)
const ROUTER := Vector2(353, 152)
const RACKS: Array[Vector2] = [Vector2(714, 236), Vector2(744, 236)]

const CYAN := Color("3ef2ff")
const CYAN_D := Color("146a8a")
const MAG := Color("ff3ea5")
const MAG_D := Color("9c1f6e")
const PAPER := Color("e9dfc6")
const ABYSS := Color(0.2, 0.01, 0.12, 0.85)

var _digital := false
var _blend := 0.0
var _ambient: CanvasModulate
var _digital_root: Node2D
var _glitch: ShaderMaterial
var _player_light: PointLight2D
var _bridge_shape: CollisionShape2D
var _fragment_taken := false
var _toast: Label
var _toast_time := 0.0


func _init() -> void:
	super()
	sample_title = "MUESTRA D · Dos mundos: colegio en pixel art + red en vectorial"
	sample_hint = "F: Visión Digital (encuentra el puente de datos y mira qué es realmente el sobre)"
	other_sample = "res://prototypes/estilos/huesos_pixelados/muestra_huesos_pixelados.tscn"


func _build_art() -> void:
	super()
	for child in get_children():
		if child is CanvasModulate:
			_ambient = child
	# La capa digital vive en su propia CanvasLayer: así la oscuridad del mundo físico no la afecta.
	var layer := CanvasLayer.new()
	layer.layer = 1
	layer.follow_viewport_enabled = true
	add_child(layer)
	_digital_root = Node2D.new()
	_digital_root.modulate.a = 0.0
	layer.add_child(_digital_root)
	var canvas := VectorCanvas.new()
	canvas.painter = _paint_digital
	canvas.animated = true
	_digital_root.add_child(canvas)
	_build_bridge()
	_build_transition_effect()
	_build_toast()


func _spawn_player() -> void:
	super()
	_player_light = add_light(Vector2(0, -16), Color(0.5, 0.95, 1.0), 70, 0.0, player)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"vision"):
		get_viewport().set_input_as_handled()
		_set_digital(not _digital)


func _process(delta: float) -> void:
	super(delta)
	if _ambient:
		_ambient.color = PHYSICAL_AMBIENT.lerp(DIGITAL_AMBIENT, _blend)
	_digital_root.modulate.a = _blend
	_player_light.energy = _blend * 1.3
	if _digital and not _fragment_taken and player.global_position.distance_to(FRAGMENT_POSITION + Vector2(0, 14)) < 18.0:
		_fragment_taken = true
		_show_toast("¡Encontraste un fragmento de datos oculto en la red!")
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)


func _set_digital(value: bool) -> void:
	_digital = value
	_bridge_shape.set_deferred(&"disabled", not value)
	var tween := create_tween()
	tween.tween_method(func(s: float) -> void: _glitch.set_shader_parameter(&"strength", s), 0.0, 0.9, 0.12)
	tween.parallel().tween_property(self, "_blend", 1.0 if value else 0.0, TRANSITION_TIME)
	tween.tween_method(func(s: float) -> void: _glitch.set_shader_parameter(&"strength", s), 0.9, 0.0, 0.3)


func _build_bridge() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	_bridge_shape = _collision_shape(DATA_BRIDGE, true)
	_bridge_shape.disabled = true
	body.add_child(_bridge_shape)
	add_child(body)


func _build_transition_effect() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch = ShaderMaterial.new()
	_glitch.shader = GLITCH_SHADER
	rect.material = _glitch
	layer.add_child(rect)


func _build_toast() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	_toast = Label.new()
	var settings := LabelSettings.new()
	settings.font_size = 20
	settings.font_color = CYAN
	settings.outline_size = 8
	settings.outline_color = Color(0.02, 0.03, 0.08)
	_toast.label_settings = settings
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(340, 640)
	_toast.size = Vector2(600, 30)
	_toast.modulate.a = 0.0
	layer.add_child(_toast)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_time = 3.0


# =====================================================================
# El mundo digital (vectorial)
# =====================================================================

func _paint_digital(c: VectorCanvas, t: float) -> void:
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
	for x in range(0, int(ROOM_SIZE.x) + 1, 32):
		c.draw_line(Vector2(x, CEILING_Y), Vector2(x, FLOOR_Y), Color(CYAN, 0.07), 0.5)
	for y in range(int(CEILING_Y), int(FLOOR_Y) + 1, 32):
		c.draw_line(Vector2(0, y), Vector2(ROOM_SIZE.x, y), Color(CYAN, 0.07), 0.5)


## Los objetos físicos se ven como contornos tenues: en la red solo importan sus datos.
func _paint_wireframe(c: VectorCanvas) -> void:
	c.draw_line(Vector2(0, FLOOR_Y), Vector2(ROOM_SIZE.x, FLOOR_Y), Color(CYAN, 0.8), 1.2, true)
	for rect in ONE_WAY_PLATFORMS:
		c.draw_rect(rect, Color(CYAN, 0.5), false, 0.8)
	var outlines: Array[Rect2] = [
		Rect2(24, 264, 80, 40), Rect2(376, 264, 64, 40), Rect2(120, 232, 36, 24),
		Rect2(172, 196, 40, 28), Rect2(284, 196, 40, 28), Rect2(232, 256, 28, 48),
		Rect2(780, 256, 30, 48),
	]
	for rect in outlines:
		c.draw_rect(rect, Color(CYAN, 0.22), false, 0.6)


func _paint_network(c: VectorCanvas, t: float) -> void:
	# Cobertura del Wi-Fi: un anillo grande que late.
	for i in 18:
		var a := i * TAU / 18.0
		c.draw_arc(ROUTER, 150.0, a, a + TAU / 36.0, 4, Color(CYAN, 0.25), 0.8, true)
	c.draw_arc(ROUTER, fmod(t * 60.0, 150.0), 0.0, TAU, 48, Color(CYAN, 0.25 * (1.0 - fmod(t * 60.0, 150.0) / 150.0)), 1.0, true)
	# Enlaces del router a los servidores, con paquetes viajando.
	for k in RACKS.size():
		var link := _link(ROUTER, RACKS[k], -60.0 - k * 20.0)
		c.draw_polyline(link, Color(CYAN, 0.55), 1.0, true)
		for p in 3:
			var point := _point_on(link, fmod(t * 0.35 + p / 3.0 + k * 0.15, 1.0))
			c.glow(point, 4.0, Color(CYAN, 0.7), 4)
			c.draw_circle(point, 0.9, Color.WHITE)
	# Nodos.
	_node(c, ROUTER, "ROUTER WI-FI", CYAN, t)
	for k in RACKS.size():
		_node(c, RACKS[k], "SRV-0%d" % (k + 1), CYAN, t + k)


func _paint_bridge(c: VectorCanvas, t: float) -> void:
	var r := DATA_BRIDGE
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
	if not _fragment_taken:
		var p := FRAGMENT_POSITION + Vector2(0, sin(t * 2.5) * 2.0)
		c.glow(p, 14.0, Color(CYAN, 0.5))
		c.draw_set_transform(p, t * 1.5)
		c.shape(PackedVector2Array([Vector2(0, -6), Vector2(4, 0), Vector2(0, 6), Vector2(-4, 0)]), Color(CYAN, 0.8), Color.WHITE, 0.7)
		c.draw_set_transform(Vector2.ZERO)


## La forma real de la amenaza: un pez abisal que usa el correo falso como carnada.
func _paint_fish(c: VectorCanvas, t: float) -> void:
	var center := FISH_CENTER + Vector2(0, sin(t * 1.2) * 3.0)
	var lure_tip := _lure.position + Vector2(0, -16) if _lure else LURE_POSITION
	# Enlace infectado: el pez roba datos del servidor (los paquetes van hacia él).
	var stolen := _link(RACKS[1], center + Vector2(-40, 10), 30.0)
	c.draw_polyline(stolen, Color(MAG, 0.7), 1.0, true)
	for p in 4:
		var point := _point_on(stolen, fmod(t * 0.5 + p / 4.0, 1.0))
		c.glow(point, 4.0, Color(MAG, 0.7), 4)
	# Antena con la carnada.
	var head := center + Vector2(-34, -24)
	var antenna := VectorCanvas.sag_curve(head, lure_tip, -30.0, 20)
	c.draw_polyline(antenna, Color(MAG, 0.9), 1.4, true)
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
	var mouth_left := center + Vector2(-56, 6)
	var jaw := PackedVector2Array([mouth_left, center + Vector2(-20, 6 - open), center + Vector2(-20, 6 + open)])
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
