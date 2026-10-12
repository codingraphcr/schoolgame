class_name LifeFragmentWindow
extends Control
## Ventana al encontrar un fragmento de vida (pausa el juego):
##   1. «¡Has obtenido un fragmento de vida!», con el pedazo brillando y [E] Reclamar.
##   2. Al reclamarlo, el pedazo entra en el cristal de vida en negro (que se va llenando) y explica
##      que se necesitan 4 para una vida completa y dónde encontrarlos. [E] Continuar.
## Reclamar suma el fragmento (GameState.add_life_fragment) y desbloquea su página del Grimorio.
## Uso: var vida_nueva: bool = await LifeFragmentWindow.claim(nodo)

signal closed(completed_life: bool)

const PANEL := Vector2(560, 250)
const NIGHT := Color("0b0716")
const FRAME := Color("8a5cff")
const TITLE_BAR := Color("2a1a5e")
const INK := Color("e9e1ff")
const MUTED := Color("a99bd6")
## Flag que desbloquea la página del Grimorio (el primer fragmento obtenido de forma oficial).
const GRIMORIO_FLAG := &"fragmento_vida_obtenido"
## Segundos antes de aceptar la tecla (para no saltarla sin querer).
const MIN_TIME := 0.6

var _step := 1
var _time := 0.0
var _completed := false
var _icon: LifeFragmentIcon
var _title: Label
var _body: Label
var _prompt: Label


## Muestra la ventana encima del juego (en pausa) y espera a que se cierre.
## Devuelve true si con este fragmento se formó una vida nueva.
static func claim(from: Node) -> bool:
	var layer := CanvasLayer.new()
	layer.name = "LifeFragmentLayer"
	layer.layer = 95
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var window := LifeFragmentWindow.new()
	window.name = "LifeFragmentWindow"
	window.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(window)
	var tree := from.get_tree()
	tree.root.add_child(layer)
	var was_paused := tree.paused
	tree.paused = true
	var completed: bool = await window.closed
	tree.paused = was_paused
	layer.queue_free()
	return completed


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := get_viewport_rect().size / 2.0
	var origin := center - PANEL / 2.0
	_icon = LifeFragmentIcon.new()
	_icon.custom_minimum_size = Vector2(120, 146)
	_icon.size = _icon.custom_minimum_size
	_icon.position = origin + Vector2(36, 62)
	var game_state := get_node_or_null("/root/GameState")
	_icon.count = game_state.life_fragments if game_state else 0
	_icon.visible = false
	add_child(_icon)
	_title = _label(origin + Vector2(190, 60), Vector2(340, 40), 24, INK)
	_body = _label(origin + Vector2(190, 104), Vector2(340, 100), 15, MUTED)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt = _label(origin + Vector2(190, PANEL.y - 44), Vector2(340, 30), 16, FRAME.lightened(0.4))
	_show_step()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	Sfx.play(&"popup_open")


func _label(at: Vector2, area: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = area
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	add_child(label)
	return label


func _show_step() -> void:
	var total := GameState.LIFE_FRAGMENTS_PER_MASK
	if _step == 1:
		_title.text = "¡Has obtenido un fragmento de vida!"
		_title.add_theme_font_size_override(&"font_size", 20)
		_body.text = "Un pedazo roto de un núcleo de integridad."
		_prompt.text = "[%s] Reclamar" % GameSettings.key_name(&"interact")
	else:
		var have := total if _completed else _icon.count
		_title.text = "¡Nueva vida!" if _completed else "Fragmento de vida  %d / %d" % [have, total]
		_title.add_theme_font_size_override(&"font_size", 22)
		_body.text = "Necesitas %d fragmentos para formar una vida completa. Puedes encontrarlos durante la historia y en encuentros con enemigos que tendrás que derrotar en el futuro." % total
		if _completed:
			_body.text = "Juntaste los %d fragmentos: se formó una vida completa." % total
		_prompt.text = "[%s] Continuar" % GameSettings.key_name(&"interact")
	_time = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _time < MIN_TIME:
		return
	var accept := event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"jump")
	if not accept:
		return
	get_viewport().set_input_as_handled()
	if _step == 1:
		_claim()
	else:
		set_process_input(false)
		Sfx.play(&"ui_accept")
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func() -> void: closed.emit(_completed))


## Reclamar: el pedazo entra en el cristal en negro y se suma el fragmento.
func _claim() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_flag(GRIMORIO_FLAG)
		_completed = game_state.add_life_fragment()
	_step = 2
	_icon.visible = true
	_icon.count = _icon.count + 1
	Sfx.play(&"life_fragment")
	_show_step()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	var origin := size / 2.0 - PANEL / 2.0
	var panel := Rect2(origin, PANEL)
	# Ventana digital: fondo oscuro, barra de título y borde violeta con brillo.
	for i in 3:
		draw_rect(panel.grow(3 + i * 3), Color(FRAME, 0.07), false, 3.0)
	draw_rect(panel, NIGHT)
	draw_rect(Rect2(origin, Vector2(PANEL.x, 26)), TITLE_BAR)
	draw_string(ThemeDB.fallback_font, origin + Vector2(12, 18), "NÚCLEO DE INTEGRIDAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
	for i in 3:
		draw_circle(origin + Vector2(PANEL.x - 16 - i * 14, 13), 4.0, [Color("ff5f8f"), Color("ffd84a"), FRAME][i])
	draw_rect(panel, FRAME, false, 2.0)
	if _step == 1:
		_draw_shard(origin + Vector2(96, 140))


## El pedazo (un cuarto del cristal) brillando, grande, en el primer paso.
func _draw_shard(center: Vector2) -> void:
	var bob := sin(_time * 2.5) * 3.0
	var c := center + Vector2(0, bob)
	for i in 5:
		draw_circle(c, 24.0 + i * 8.0, Color(MaskIcon.GLOW, 0.06))
	var s := 44.0
	var piece := PackedVector2Array([c + Vector2(-14, 18), c + Vector2(-14, -s), c + Vector2(s * 0.42 - 14, -s * 0.4),
		c + Vector2(s * 0.62 - 14, 18), c + Vector2(6, 10), c + Vector2(-4, 22)])
	draw_colored_polygon(piece, MaskIcon.DEEP)
	var middle := Vector2.ZERO
	for p in piece:
		middle += p
	middle /= piece.size()
	var inner := PackedVector2Array()
	for p in piece:
		inner.append(middle.lerp(p, 0.62))
	draw_colored_polygon(inner, MaskIcon.BRIGHT.lerp(MaskIcon.PALE, 0.3 + 0.2 * sin(_time * 3.0)))
	var edge := piece.duplicate()
	edge.append(edge[0])
	draw_polyline(edge, MaskIcon.PALE, 2.5, true)
	draw_circle(middle, 4.0, MaskIcon.CORE)
	var twinkle := maxf(0.0, sin(_time * 4.0))
	draw_line(c + Vector2(-40, -20), c + Vector2(-40, -20 + 10.0 * twinkle), MaskIcon.PALE, 2.0)
	draw_line(c + Vector2(34, 26), c + Vector2(34 + 8.0 * twinkle, 26), MaskIcon.PALE, 2.0)
