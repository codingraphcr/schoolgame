class_name LoadingScreen
extends CanvasLayer
## Pantalla de carga "digital": lluvia de código, título, líneas de estado que van apareciendo y
## una barra de progreso. Se usa al entrar a una computadora (el alma de Kai se digitaliza).
## Uso: await LoadingScreen.show_loading(self, "CONECTANDO...", ["línea 1", "línea 2"], 2.8)

const CYAN := Color("3ef2ff")
const VIOLET := Color("a77bff")
const BACKGROUND := Color(0.02, 0.03, 0.08)
const GLYPHS := "0101{}<>/#$%=+*ABCDEF0123456789"

var _rain: Control
var _title: Label
var _status: Label
var _bar_fill: ColorRect
var _columns: Array = []  # [x, y, velocidad, texto]


## Crea la pantalla, la muestra durante duration segundos y la deja visible (la escena siguiente
## la reemplaza). Devuelve la pantalla por si se quiere quitar a mano.
static func show_loading(from: Node, title: String, lines: PackedStringArray, duration: float) -> LoadingScreen:
	var screen := LoadingScreen.new()
	from.get_tree().root.add_child(screen)
	await screen.run(title, lines, duration)
	return screen


func _ready() -> void:
	layer = 90
	add_to_group(&"loading_screen")
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_rain = Control.new()
	_rain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rain.draw.connect(_draw_rain)
	add_child(_rain)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.custom_minimum_size = Vector2(560, 0)
	center.add_theme_constant_override("separation", 14)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_title = _label(center, 34, CYAN)
	_status = _label(center, 18, Color(0.85, 0.92, 1.0))
	var bar_back := ColorRect.new()
	bar_back.color = Color(0.08, 0.12, 0.22)
	bar_back.custom_minimum_size = Vector2(560, 10)
	bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(bar_back)
	_bar_fill = ColorRect.new()
	_bar_fill.color = CYAN
	_bar_fill.size = Vector2(0, 10)
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_back.add_child(_bar_fill)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 48:
		var text := ""
		for j in 14:
			text += GLYPHS[rng.randi_range(0, GLYPHS.length() - 1)]
		_columns.append([i * 27.0 + rng.randf_range(0, 10), rng.randf_range(-700, 0), rng.randf_range(90, 260), text])


## Desvanece y elimina todas las pantallas de carga abiertas (al llegar a la sala nueva).
static func dismiss_all(tree: SceneTree) -> void:
	for screen in tree.get_nodes_in_group(&"loading_screen"):
		(screen as LoadingScreen).dismiss()


func dismiss() -> void:
	remove_from_group(&"loading_screen")
	var fade := create_tween().set_parallel()
	for child in get_children():
		if child is CanvasItem:
			fade.tween_property(child, "modulate:a", 0.0, 0.4)
	await fade.finished
	queue_free()


func run(title: String, lines: PackedStringArray, duration: float) -> void:
	_title.text = title
	var tween := create_tween()
	tween.tween_property(_bar_fill, "size:x", 560.0, duration).set_trans(Tween.TRANS_SINE)
	for i in lines.size():
		_status.text = lines[i]
		await get_tree().create_timer(duration / maxf(lines.size(), 1)).timeout
	if tween.is_running():
		await tween.finished


func _process(delta: float) -> void:
	var height := float(get_viewport().get_visible_rect().size.y)
	for column in _columns:
		column[1] += column[2] * delta
		if column[1] > height + 20.0:
			column[1] = -420.0
	_title.modulate.a = 0.8 + 0.2 * sin(Time.get_ticks_msec() / 90.0)
	_rain.queue_redraw()


func _draw_rain() -> void:
	var font := ThemeDB.fallback_font
	for column in _columns:
		var text: String = column[3]
		for j in text.length():
			var alpha := 0.08 + 0.35 * float(j) / text.length()
			var color := CYAN if j == text.length() - 1 else Color(VIOLET if j % 5 == 0 else CYAN, alpha)
			_rain.draw_string(font, Vector2(column[0], column[1] + j * 26.0), text[j], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)


func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", BACKGROUND)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
