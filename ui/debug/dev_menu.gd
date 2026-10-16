extends CanvasLayer
## Menú de pruebas (F9): saltar a cualquier punto de la historia sin rejugar (DevPoints) y trucos para
## probar (sin daño, energía y Dominio llenos, doble salto). SOLO existe al correr el juego desde el
## editor de Godot: en el juego exportado (la versión de prueba, Steam) no hace nada.
## Saltar no toca las ranuras de guardado: la partida de prueba no se guarda (active_slot = 0).

const PANEL := Color(0.03, 0.04, 0.1, 0.94)
const CYAN := Color("3ef2ff")
const GOLD := Color("ffd166")

## Trucos (se aplican cada cuadro al Kai de la sala actual).
var god_mode := false
var full_energy := false
var double_jump := false

var _root: Control
var _was_paused := false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_available():
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		return
	_build()
	_root.hide()


## Solo al correr desde el editor (en el juego exportado no existe la función «editor»).
static func is_available() -> bool:
	return OS.has_feature("editor")


func is_open() -> bool:
	return _root != null and _root.visible


func toggle() -> void:
	if _root.visible:
		close()
	else:
		_root.show()
		_was_paused = get_tree().paused
		get_tree().paused = true
		(_root.find_child("Primero", true, false) as Control).grab_focus.call_deferred()


func close() -> void:
	_root.hide()
	get_tree().paused = _was_paused


## Salta a un punto de la historia (DevPoints.POINTS[index]).
func jump(index: int) -> void:
	var point: Dictionary = DevPoints.POINTS[index]
	if is_open():
		close()
	get_tree().paused = false
	var saves := get_node("/root/SaveManager")
	saves.active_slot = 0  # No se guarda: las ranuras quedan como estaban.
	get_node("/root/DigitalVision").reset()
	get_node("/root/World").new_world()
	DevPoints.prepare(point, get_node("/root/GameState"))
	CombatClock.reset()
	get_node("/root/SceneManager").go_to_room(point["escena"], point.get("entrada", &""), point.get("sala", &""))
	print("Menú de pruebas: ", point["grupo"], " · ", point["nombre"])


## Vuelve a ver la cinemática inicial como en una partida nueva (sin ranura: no se guarda nada).
func play_intro() -> void:
	if is_open():
		close()
	get_tree().paused = false
	get_node("/root/SaveManager").active_slot = 0
	get_node("/root/DigitalVision").reset()
	get_node("/root/World").new_world()
	var state := get_node("/root/GameState")
	state.reset()
	state.set_flag(&"menu_pruebas")
	state.start_quest(&"prologo")
	CombatClock.reset()
	get_node("/root/SceneManager").change_scene(SceneManager.INTRO)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F9:
		get_viewport().set_input_as_handled()
		toggle()
	elif is_open() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	if god_mode:
		player.damage.protected = true
	if full_energy:
		player.set_energy(player.max_energy)
		if player.domain and player.domain.is_unlocked() and not player.domain.active:
			player.domain.set_charge(player.domain.cost())
	if double_jump:
		player.can_double_jump = true


func _build() -> void:
	_root = CenterContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 600)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = CYAN
	style.set_border_width_all(2)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var title := Label.new()
	title.text = "MENÚ DE PRUEBAS · F9 (solo en el editor)"
	title.add_theme_color_override("font_color", CYAN)
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	var note := Label.new()
	note.text = "Salta a un punto de la historia con todo lo anterior hecho. No se guarda."
	note.add_theme_font_size_override("font_size", 13)
	column.add_child(note)
	var cheats := HBoxContainer.new()
	column.add_child(cheats)
	for data in [["Sin daño", "god_mode"], ["Energía y Dominio llenos", "full_energy"], ["Doble salto", "double_jump"]]:
		var check := CheckButton.new()
		check.text = data[0]
		var property: String = data[1]
		check.toggled.connect(func(on: bool) -> void: set(property, on))
		cheats.add_child(check)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 420)
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var group := ""
	for i in DevPoints.POINTS.size():
		var point: Dictionary = DevPoints.POINTS[i]
		if point["grupo"] != group:
			group = point["grupo"]
			var header := Label.new()
			header.text = group.to_upper()
			header.add_theme_color_override("font_color", GOLD)
			list.add_child(header)
		var button := Button.new()
		button.text = point["nombre"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(jump.bind(i))
		if i == 0:
			button.name = "Primero"
		list.add_child(button)
	var intro_button := Button.new()
	intro_button.name = "Cinematica"
	intro_button.text = "Ver la cinemática inicial (partida nueva, sin guardar)"
	intro_button.pressed.connect(play_intro)
	column.add_child(intro_button)
	var close_button := Button.new()
	close_button.text = "Cerrar (F9 o Esc)"
	close_button.pressed.connect(close)
	column.add_child(close_button)
