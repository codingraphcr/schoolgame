class_name DialogueBox
extends Control
## Caja de diálogo al estilo Hades: retrato grande del que habla (Kai a la izquierda, los demás a la
## derecha), placa oscura con nombre y título, caja clara con marco del color del personaje
## (DialogueFrameArt y DialogueNamePlate) y un triángulo para continuar. El texto aparece
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
const PORTRAIT_HEIGHT := 600.0
## Cuánto se puede agrandar un retrato chico (las expresiones son primeros planos de la cara).
const MAX_UPSCALE := 2.5
const BOX_SIDE_MARGIN := 110.0
const BOX_PORTRAIT_GAP := 350.0
const BOX_NARRATION_MARGIN := 230.0
const SLIDE := 48.0
const DIMMED := 0.4
## Cuánto se aleja hacia su borde el retrato del que no habla.
const BACK_OFF := 26.0
## Distancia de la placa del nombre al borde de la caja.
const PLATE_INSET := 34.0
const DEFAULT_ACCENT := Color(0.243, 0.949, 1.0)
## Color normal del texto (sobre la caja clara).
const TEXT_COLOR := Color(0.1, 0.09, 0.11)

var _lines: Array[Dictionary] = []
var _index := -1
var _is_playing := false
## Si el texto de la línea actual tiembla (DialogueCharacter.glitch).
var _glitch := false
## Posición normal del texto (el temblor lo mueve alrededor de ella).
var _text_rest := Vector2.ZERO
## Pausa que le queda a la escritura irregular antes de seguir (con glitch).
var _type_pause := 0.0
## Personaje que ocupa cada lado (o null).
var _side_character := { DialogueCharacter.Side.LEFT: null, DialogueCharacter.Side.RIGHT: null }

@onready var _dim: TextureRect = $Dim
@onready var _portraits := { DialogueCharacter.Side.LEFT: $PortraitLeft as TextureRect, DialogueCharacter.Side.RIGHT: $PortraitRight as TextureRect }
@onready var _frame: Control = $Frame
@onready var _box: DialogueFrameArt = $Frame/Box
@onready var _name_plate: DialogueNamePlate = %NamePlate
@onready var _speaker: Label = %Speaker
@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _continue: Control = %Continue
@onready var _triangle: Polygon2D = $Frame/Continue/Triangle
@onready var _triangle_back: Polygon2D = $Frame/Continue/Back


## La caja de diálogo de la sala actual (vive en el HUD).
static func find(from: Node) -> DialogueBox:
	return from.get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox


func _ready() -> void:
	add_to_group(&"dialogue_box")
	visible = false
	for portrait: TextureRect in _portraits.values():
		portrait.material = (portrait.material as ShaderMaterial).duplicate()
	_load_characters()
	_text_rest = Vector2(_text.offset_left, _text.offset_top)


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
		_type(delta)
	_continue.visible = _text.visible_ratio >= 1.0
	# El triángulo late y sube y baja un poco.
	var beat := absf(sin(Time.get_ticks_msec() / 260.0))
	_continue.modulate.a = 0.45 + 0.55 * beat
	_triangle.position.y = 3.0 * beat
	_triangle_back.position.y = _triangle.position.y
	_update_glitch()


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
	var previous_speaker := _speaker.text if _name_plate.visible else ""
	_speaker.text = character.display_name if character else speaker
	_title.text = character.title if character else ""
	_title.visible = not _title.text.is_empty()
	_name_plate.visible = not speaker.is_empty()
	# La narración (sin orador) va centrada.
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if speaker.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
	var accent := character.accent if character else DEFAULT_ACCENT
	_title.add_theme_color_override(&"font_color", accent)
	_box.accent = accent
	_name_plate.accent = accent
	_triangle_back.color = accent
	var text_color := character.text_color if character and character.text_color.a > 0.0 else TEXT_COLOR
	_text.add_theme_color_override(&"font_color", text_color)
	_glitch = character != null and character.glitch
	_update_glitch()
	var active_side := _update_portraits(character, String(line.get("expression", "")))
	_place_frame(active_side, index == 0 or previous_speaker != _speaker.text)
	_text.text = line["text"]
	_text.visible_ratio = 0.0
	_type_pause = 0.0
	_continue.visible = false
	line_started.emit(index)


## Muestra el retrato del que habla en su lado y oscurece y aleja el del otro lado.
## Devuelve el lado del que habla (-1 si no tiene retrato).
func _update_portraits(character: DialogueCharacter, expression: String) -> int:
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
		var active: bool = side == active_side
		portrait.z_index = 1 if active else 0
		if not portrait.visible:
			continue
		var fade := portrait.material as ShaderMaterial
		var outward := -1.0 if side == DialogueCharacter.Side.LEFT else 1.0
		var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_method(func(value: float) -> void: fade.set_shader_parameter(&"brightness", value),
			float(fade.get_shader_parameter(&"brightness")), 1.0 if active else DIMMED, 0.2)
		tween.tween_property(portrait, "position:x", float(portrait.get_meta(&"base_x")) + (0.0 if active else outward * BACK_OFF), 0.25)
	return active_side


func _place_portrait(portrait: TextureRect, texture: Texture2D, side: int, flipped: bool) -> void:
	var shown := texture.get_size() * minf(PORTRAIT_HEIGHT / texture.get_height(), MAX_UPSCALE)
	var x := 0.0 if side == DialogueCharacter.Side.LEFT else size.x - shown.x
	portrait.texture = texture
	portrait.flip_h = flipped
	portrait.size = shown
	portrait.set_meta(&"base_x", x)
	(portrait.material as ShaderMaterial).set_shader_parameter(&"inner_at_uv_one", (side == DialogueCharacter.Side.LEFT) != flipped)
	(portrait.material as ShaderMaterial).set_shader_parameter(&"brightness", 1.0)
	portrait.visible = true
	# Entra deslizándose desde su lado y desde abajo.
	var from := -SLIDE if side == DialogueCharacter.Side.LEFT else SLIDE
	portrait.position = Vector2(x + from, size.y - shown.y + 20.0)
	portrait.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(portrait, "position:y", size.y - shown.y, 0.3)
	tween.tween_property(portrait, "modulate:a", 1.0, 0.18)


## Corre la caja hacia el lado contrario al retrato del que habla (centrada si es narración) y,
## si cambió quien habla, la hace aparecer con un pequeño salto, como en Hades.
func _place_frame(active_side: int, pop: bool) -> void:
	var left := BOX_NARRATION_MARGIN
	var right := BOX_NARRATION_MARGIN
	if active_side == DialogueCharacter.Side.LEFT:
		left = BOX_PORTRAIT_GAP
		right = BOX_SIDE_MARGIN
	elif active_side == DialogueCharacter.Side.RIGHT:
		left = BOX_SIDE_MARGIN
		right = BOX_PORTRAIT_GAP
	var mirrored := active_side == DialogueCharacter.Side.RIGHT
	_box.mirrored = mirrored
	_name_plate.mirrored = mirrored
	_frame.offset_left = left
	_frame.offset_right = -right
	# La placa va del lado del retrato y se apoya sobre el borde de arriba de la caja.
	_name_plate.anchor_left = 1.0 if mirrored else 0.0
	_name_plate.anchor_right = _name_plate.anchor_left
	_name_plate.grow_horizontal = Control.GROW_DIRECTION_BEGIN if mirrored else Control.GROW_DIRECTION_END
	_name_plate.offset_left = -PLATE_INSET if mirrored else PLATE_INSET
	_name_plate.offset_right = _name_plate.offset_left
	if not pop:
		return
	_frame.pivot_offset = Vector2(_frame.size.x * (0.85 if mirrored else 0.15), _frame.size.y)
	_frame.scale = Vector2(0.94, 0.94)
	_frame.modulate.a = 0.4
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_frame, "scale", Vector2.ONE, 0.22)
	tween.tween_property(_frame, "modulate:a", 1.0, 0.12)
	var plate_from := 30.0 if mirrored else -30.0
	_name_plate.position.x += plate_from
	tween.tween_property(_name_plate, "position:x", _name_plate.position.x - plate_from, 0.25)


## Escribe el texto letra por letra. Con glitch la escritura es irregular: cambia de velocidad,
## se traba en pausas cortas y a veces escupe varias letras de golpe.
## La velocidad depende de las opciones (GameSettings): en "instantánea" la línea aparece entera.
func _type(delta: float) -> void:
	var total := maxi(_text.text.length(), 1)
	var factor := GameSettings.text_speed_factor()
	if factor <= 0.0:
		_text.visible_ratio = 1.0
		return
	if not _glitch:
		_text.visible_ratio = minf(_text.visible_ratio + characters_per_second * factor * delta / total, 1.0)
		return
	if _type_pause > 0.0:
		_type_pause -= delta
		return
	var before := _text.visible_characters
	var speed := characters_per_second * factor * randf_range(0.25, 1.6)
	_text.visible_ratio = minf(_text.visible_ratio + speed * delta / total, 1.0)
	if _text.visible_characters == before or _text.visible_ratio >= 1.0:
		return
	var roll := randf()
	if roll < 0.12:
		_type_pause = randf_range(0.12, 0.4)
	elif roll < 0.18:
		_text.visible_characters = mini(_text.visible_characters + randi_range(2, 4), total)


## Interferencia: el texto salta un par de píxeles y parpadea de vez en cuando
## (no pasa si en las opciones se reducen los efectos glitch).
func _update_glitch() -> void:
	var rest := _text_rest
	if not _glitch or GameSettings.reduce_glitch or randf() > 0.12:
		_text.position = rest
		_text.modulate.a = 1.0
		_name_plate.modulate.a = 1.0
		return
	_text.position = rest + Vector2(randf_range(-3.0, 3.0), randf_range(-1.0, 1.0))
	_text.modulate.a = randf_range(0.55, 0.9)
	_name_plate.modulate.a = randf_range(0.6, 1.0)
