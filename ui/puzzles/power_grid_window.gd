class_name PowerGridWindow
extends CanvasLayer
## La ventana del tablero de distribución eléctrica (PowerGrid). Una ficha está seleccionada (recuadro dorado): se mueve
## con las acciones de movimiento (W/A/S/D o las flechas por defecto; respeta el remapeo de Opciones) y se gira con la
## de interactuar (E). La energía se ve correr desde la fuente; al llegar al núcleo, el tablero queda resuelto. Se puede
## reiniciar el tablero y salir (Esc) sin perder nada. Pausa el juego. Uso: var solved: bool = await PowerGridWindow.open(n, g).closed

signal solved
signal closed(was_solved: bool)

const PANEL := Color("101624")
const BORDER := Color("6fd3ff")
const INK := Color("e8eef8")
const MUTED := Color("8a94a8")
const CYAN := Color("3ef2ff")
const GOLD := Color("f2c14e")
const OFF := Color("3a4258")

var grid: PowerGrid
var rotations: PackedInt32Array = []
var cursor := Vector2i.ZERO
var is_solved := false

var _board: Control
var _status: Label
var _was_paused := false
var _clock := 0.0


static func open(from: Node, power_grid: PowerGrid) -> PowerGridWindow:
	var window := PowerGridWindow.new()
	window.grid = power_grid
	from.get_tree().current_scene.add_child(window)
	return window


func _ready() -> void:
	layer = 70
	add_to_group(&"power_grid_window")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	reset()
	cursor = grid.source
	_build()
	Sfx.play(&"popup_open")


func _process(delta: float) -> void:
	_clock += delta
	_board.queue_redraw()


## Vuelve las fichas a como estaban.
func reset() -> void:
	rotations = grid.start_rotations.duplicate()
	is_solved = false
	if _status:
		_update_status()


func move_cursor(direction: Vector2i) -> void:
	cursor = Vector2i(clampi(cursor.x + direction.x, 0, grid.size.x - 1), clampi(cursor.y + direction.y, 0, grid.size.y - 1))
	Sfx.play(&"ui_move")


## Gira la ficha seleccionada un cuarto de vuelta.
func rotate_selected() -> void:
	if is_solved:
		return
	var index := grid.index_of(cursor)
	if grid.tiles[index] == PowerGrid.Tile.VACIA:
		return
	rotations[index] = (rotations[index] + 1) % 4
	Sfx.play(&"terminal_key")
	_update_status()
	if grid.is_solved(rotations):
		is_solved = true
		Sfx.play(&"terminal_ok")
		_update_status()
		solved.emit()


func close() -> void:
	get_tree().paused = _was_paused
	Sfx.play(&"popup_close")
	closed.emit(is_solved)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed(&"move_up"):
		get_viewport().set_input_as_handled()
		move_cursor(Vector2i.UP)
	elif event.is_action_pressed(&"move_down"):
		get_viewport().set_input_as_handled()
		move_cursor(Vector2i.DOWN)
	elif event.is_action_pressed(&"move_left"):
		get_viewport().set_input_as_handled()
		move_cursor(Vector2i.LEFT)
	elif event.is_action_pressed(&"move_right"):
		get_viewport().set_input_as_handled()
		move_cursor(Vector2i.RIGHT)
	elif event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		if is_solved:
			close()
		else:
			rotate_selected()


func _update_status() -> void:
	if is_solved:
		_status.text = "¡La energía llega al núcleo! (E o Esc para seguir)"
		_status.add_theme_color_override(&"font_color", Color("7ee08a"))
	else:
		_status.text = "La energía todavía no llega al núcleo."
		_status.add_theme_color_override(&"font_color", MUTED)


## El nombre de la tecla de esa acción (respeta el remapeo de Opciones).
func _key(action: StringName) -> String:
	return GameSettings.key_name(action)


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.05, 0.75)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(760, 560)
	panel.position = Vector2(-380, -280)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	panel.add_child(column)
	column.add_child(_label("TABLERO DE DISTRIBUCIÓN ELÉCTRICA", 18, BORDER))
	column.add_child(_label("Gira las fichas para que la energía vaya de la fuente (izquierda) al núcleo (derecha).", 15, INK))
	_board = Control.new()
	_board.custom_minimum_size = Vector2(720, 340)
	_board.draw.connect(_draw_board)
	column.add_child(_board)
	_status = _label("", 15, MUTED)
	column.add_child(_status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	column.add_child(row)
	var restart := Button.new()
	restart.text = "Reiniciar el tablero"
	restart.custom_minimum_size = Vector2(200, 36)
	InspectionWindow.style_button(restart)
	restart.focus_mode = Control.FOCUS_NONE
	restart.pressed.connect(reset)
	row.add_child(restart)
	var leave := Button.new()
	leave.text = "Salir"
	leave.custom_minimum_size = Vector2(100, 36)
	InspectionWindow.style_button(leave)
	leave.focus_mode = Control.FOCUS_NONE
	leave.pressed.connect(close)
	row.add_child(leave)
	column.add_child(_label("%s %s %s %s: mover   ·   %s: girar la ficha   ·   Esc: salir" % [
		_key(&"move_up"), _key(&"move_left"), _key(&"move_down"), _key(&"move_right"), _key(&"interact")], 13, MUTED))
	_update_status()


func _draw_board() -> void:
	var cell := minf((_board.size.x - 160.0) / grid.size.x, _board.size.y / grid.size.y)
	var origin := Vector2((_board.size.x - cell * grid.size.x) / 2.0, (_board.size.y - cell * grid.size.y) / 2.0)
	var lit := grid.powered(rotations)
	# La fuente y el núcleo.
	var source_pos := origin + Vector2(-34, (grid.source.y + 0.5) * cell)
	_board.draw_rect(Rect2(source_pos - Vector2(20, 18), Vector2(28, 36)), Color("2a3a5a"))
	_board.draw_string(ThemeDB.fallback_font, source_pos + Vector2(-26, -24), "FUENTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CYAN)
	_board.draw_line(source_pos + Vector2(8, 0), origin + Vector2(0, (grid.source.y + 0.5) * cell), CYAN, 6.0)
	var core_pos := origin + Vector2(grid.size.x * cell + 34, (grid.target.y + 0.5) * cell)
	var core_on := is_solved
	_board.draw_circle(core_pos, 18.0 + (2.0 * sin(_clock * 4.0) if core_on else 0.0), CYAN if core_on else OFF)
	_board.draw_string(ThemeDB.fallback_font, core_pos + Vector2(-22, -26), "NÚCLEO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CYAN if core_on else MUTED)
	_board.draw_line(origin + Vector2(grid.size.x * cell, (grid.target.y + 0.5) * cell), core_pos - Vector2(18, 0), CYAN if core_on else OFF, 6.0)
	# Las fichas.
	for y in grid.size.y:
		for x in grid.size.x:
			var here := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)).grow(-3)
			_board.draw_rect(rect, Color("161e30"))
			_board.draw_rect(rect, Color("2a3450"), false, 1.0)
			var mask := grid.mask_at(rotations, here)
			var color := CYAN if lit.has(here) else OFF
			var center := rect.get_center()
			for side in [PowerGrid.N, PowerGrid.E, PowerGrid.S, PowerGrid.W]:
				if mask & side:
					var dir := { PowerGrid.N: Vector2.UP, PowerGrid.E: Vector2.RIGHT, PowerGrid.S: Vector2.DOWN, PowerGrid.W: Vector2.LEFT }[side] as Vector2
					_board.draw_line(center, center + dir * (cell / 2.0 - 3.0), color, 8.0)
			if mask != 0:
				_board.draw_circle(center, 6.0, color)
			if here == cursor:
				_board.draw_rect(rect.grow(1), GOLD, false, 3.0)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
