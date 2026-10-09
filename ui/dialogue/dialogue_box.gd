class_name DialogueBox
extends Control
## Caja de diálogo en la parte superior de la pantalla (como en Hollow Knight: no tapa a los personajes). El texto aparece letra por letra;
## E o Espacio lo completan y, si ya está completo, pasan a la siguiente línea.
## Uso: await DialogueBox.find(self).play(dialogo)  (con DialogueBox.find se obtiene la de la sala).

signal line_started(index: int)
signal finished

## Letras por segundo.
@export var characters_per_second := 45.0

var _lines: Array[Dictionary] = []
var _index := -1
var _is_playing := false

@onready var _speaker: Label = %Speaker
@onready var _text: Label = %Text
@onready var _continue: Label = %Continue


## La caja de diálogo de la sala actual (vive en el HUD).
static func find(from: Node) -> DialogueBox:
	return from.get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox


func _ready() -> void:
	add_to_group(&"dialogue_box")
	visible = false


func is_playing() -> bool:
	return _is_playing


## Muestra el diálogo completo y termina cuando el jugador pasa la última línea.
func play(dialogue: Dialogue) -> void:
	_lines = dialogue.get_lines() if dialogue else ([] as Array[Dictionary])
	if _lines.is_empty():
		return
	_is_playing = true
	visible = true
	_show_line(0)
	await finished


func _process(delta: float) -> void:
	if not _is_playing:
		return
	if _text.visible_ratio < 1.0:
		var total := maxi(_text.text.length(), 1)
		_text.visible_ratio = minf(_text.visible_ratio + characters_per_second * delta / total, 1.0)
	_continue.visible = _text.visible_ratio >= 1.0
	_continue.modulate.a = 0.5 + 0.5 * absf(sin(Time.get_ticks_msec() / 250.0))


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


func _show_line(index: int) -> void:
	_index = index
	var line: Dictionary = _lines[index]
	_speaker.text = line["speaker"]
	_speaker.visible = not String(line["speaker"]).is_empty()
	_text.text = line["text"]
	_text.visible_ratio = 0.0
	_continue.visible = false
	line_started.emit(index)
