class_name DialogueBox
extends Control
## Caja de diálogo al estilo Hades: retrato grande del que habla (Kai a la izquierda, los demás a la
## derecha), placa con nombre y título, la caja abajo y un triángulo para continuar. El texto aparece
## letra por letra; E o Espacio lo completan y, si ya está completo, pasan a la siguiente línea.
## Los personajes (retrato, título, color, lado) son recursos DialogueCharacter de data/characters/.
## Uso: await DialogueBox.find(self).play(dialogo)  (con DialogueBox.find se obtiene la de la sala).

signal line_started(index: int)
signal finished

## Letras por segundo.
@export var characters_per_second := 45.0
## Carpeta con los personajes (DialogueCharacter). Los que hablan sin estar ahí solo muestran su nombre.
@export_dir var characters_dir := "res://data/characters"
## Personajes extra (además de los de characters_dir).
@export var characters: Array[DialogueCharacter] = []

## Alto de los retratos en pantalla y separación de la caja cuando hay un retrato a un lado.
const PORTRAIT_HEIGHT := 540.0
## Cuánto se puede agrandar un retrato chico (las expresiones son primeros planos de la cara).
const MAX_UPSCALE := 2.5
const BOX_SIDE_MARGIN := 70.0
const BOX_PORTRAIT_GAP := 330.0
const BOX_NARRATION_MARGIN := 200.0
const SLIDE := 48.0
const DIMMED := 0.45
const DEFAULT_ACCENT := Color(0.243, 0.949, 1.0)

var _lines: Array[Dictionary] = []
var _index := -1
var _is_playing := false
## Personaje que ocupa cada lado (o null).
var _side_character := { DialogueCharacter.Side.LEFT: null, DialogueCharacter.Side.RIGHT: null }

@onready var _dim: TextureRect = $Dim
@onready var _portraits := { DialogueCharacter.Side.LEFT: $PortraitLeft as TextureRect, DialogueCharacter.Side.RIGHT: $PortraitRight as TextureRect }
@onready var _frame: Control = $Frame
@onready var _name_plate: PanelContainer = %NamePlate
@onready var _speaker: Label = %Speaker
@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _continue: Control = %Continue
@onready var _triangle: Polygon2D = $Frame/Continue/Triangle


## La caja de diálogo de la sala actual (vive en el HUD).
static func find(from: Node) -> DialogueBox:
	return from.get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox


func _ready() -> void:
	add_to_group(&"dialogue_box")
	visible = false
	for portrait: TextureRect in _portraits.values():
		portrait.material = (portrait.material as ShaderMaterial).duplicate()
	_load_characters()


## Agrega los personajes de characters_dir (un .tres por personaje).
func _load_characters() -> void:
	if characters_dir.is_empty() or not DirAccess.dir_exists_absolute(characters_dir):
		return
	for file in ResourceLoader.list_directory(characters_dir):
		var character := load(characters_dir.path_join(file)) as DialogueCharacter
		if character and character not in characters:
			characters.append(character)


func is_playing() -> bool:
	return _is_playing


## Muestra el diálogo completo y termina cuando el jugador pasa la última línea.
func play(dialogue: Dialogue) -> void:
	_lines = dialogue.get_lines() if dialogue else ([] as Array[Dictionary])
	if _lines.is_empty():
		return
	_is_playing = true
	visible = true
	for side in _portraits:
		_side_character[side] = null
		_portraits[side].visible = false
	_dim.modulate.a = 0.0
	create_tween().tween_property(_dim, "modulate:a", 1.0, 0.2)
	_show_line(0)
	await finished


func _process(delta: float) -> void:
	if not _is_playing:
		return
	if _text.visible_ratio < 1.0:
		var total := maxi(_text.text.length(), 1)
		_text.visible_ratio = minf(_text.visible_ratio + characters_per_second * delta / total, 1.0)
	_continue.visible = _text.visible_ratio >= 1.0
	# El triángulo late y sube y baja un poco.
	var beat := absf(sin(Time.get_ticks_msec() / 260.0))
	_continue.modulate.a = 0.45 + 0.55 * beat
	_triangle.position.y = 3.0 * beat


func _unhandled_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance()


## Completa la línea actual o pasa a la siguiente.
func advance() -> void:
	if _text.visible_ratio < 1.0:
		_text.visible_ratio = 1.0
	elif _index + 1 < _lines.size():
		_show_line(_index + 1)
	else:
		_is_playing = false
		visible = false
		finished.emit()


## Personaje registrado para un nombre del diálogo (o null).
func character_for(speaker: String) -> DialogueCharacter:
	for character in characters:
		if character and character.matches(speaker):
			return character
	return null


func _show_line(index: int) -> void:
	_index = index
	var line: Dictionary = _lines[index]
	var speaker := String(line["speaker"])
	var character := character_for(speaker)
	_speaker.text = character.display_name if character else speaker
	_title.text = character.title if character else ""
	_title.visible = not _title.text.is_empty()
	_name_plate.visible = not speaker.is_empty()
	var accent := character.accent if character else DEFAULT_ACCENT
	_speaker.add_theme_color_override(&"font_color", accent)
	_triangle.color = accent
	var style := _name_plate.get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
	style.border_color = accent
	_name_plate.add_theme_stylebox_override(&"panel", style)
	_update_portraits(character, String(line.get("expression", "")))
	_text.text = line["text"]
	_text.visible_ratio = 0.0
	_continue.visible = false
	line_started.emit(index)


## Muestra el retrato del que habla en su lado y atenúa el del otro lado.
func _update_portraits(character: DialogueCharacter, expression: String) -> void:
	var active_side := -1
	if character and character.portrait:
		active_side = character.side
		var portrait: TextureRect = _portraits[active_side]
		var texture := character.portrait_for(expression)
		var changed: bool = _side_character[active_side] != character or portrait.texture != texture or not portrait.visible
		_side_character[active_side] = character
		if changed:
			_place_portrait(portrait, texture, active_side, character.flip_portrait)
	for side in _portraits:
		var portrait: TextureRect = _portraits[side]
		(portrait.material as ShaderMaterial).set_shader_parameter(&"brightness", 1.0 if side == active_side else DIMMED)
		portrait.z_index = 1 if side == active_side else 0
	_place_frame(active_side)


func _place_portrait(portrait: TextureRect, texture: Texture2D, side: int, flipped: bool) -> void:
	var shown := texture.get_size() * minf(PORTRAIT_HEIGHT / texture.get_height(), MAX_UPSCALE)
	var x := 0.0 if side == DialogueCharacter.Side.LEFT else size.x - shown.x
	portrait.texture = texture
	portrait.flip_h = flipped
	portrait.size = shown
	portrait.position = Vector2(x, size.y - shown.y)
	(portrait.material as ShaderMaterial).set_shader_parameter(&"inner_at_uv_one", (side == DialogueCharacter.Side.LEFT) != flipped)
	portrait.visible = true
	# Entra deslizándose desde su lado.
	var from := -SLIDE if side == DialogueCharacter.Side.LEFT else SLIDE
	portrait.position.x += from
	portrait.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(portrait, "position:x", x, 0.22)
	tween.tween_property(portrait, "modulate:a", 1.0, 0.18)


## Corre la caja hacia el lado contrario al retrato del que habla (centrada si es narración).
func _place_frame(active_side: int) -> void:
	var left := BOX_NARRATION_MARGIN
	var right := BOX_NARRATION_MARGIN
	if active_side == DialogueCharacter.Side.LEFT:
		left = BOX_PORTRAIT_GAP
		right = BOX_SIDE_MARGIN
	elif active_side == DialogueCharacter.Side.RIGHT:
		left = BOX_SIDE_MARGIN
		right = BOX_PORTRAIT_GAP
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_frame, "offset_left", left, 0.18)
	tween.tween_property(_frame, "offset_right", -right, 0.18)
	# La placa con el nombre va del lado del que habla.
	_name_plate.set_anchors_preset(Control.PRESET_TOP_RIGHT if active_side == DialogueCharacter.Side.RIGHT else Control.PRESET_TOP_LEFT)
	_name_plate.grow_horizontal = Control.GROW_DIRECTION_BEGIN if active_side == DialogueCharacter.Side.RIGHT else Control.GROW_DIRECTION_END
	_name_plate.offset_left = -28.0 if active_side == DialogueCharacter.Side.RIGHT else 28.0
	_name_plate.offset_right = _name_plate.offset_left
	_name_plate.offset_top = -40.0
