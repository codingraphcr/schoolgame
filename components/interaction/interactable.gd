class_name Interactable
extends Area2D
## Algo con lo que Kai puede interactuar (personas, computadoras, objetos). Al acercarse muestra
## el aviso (p. ej. "E: hablar") y con E emite interacted. Necesita una CollisionShape2D hija.
## Mientras busy es true (diálogo en curso, evento) no responde ni muestra el aviso.

signal interacted(player: Player)

const PROMPT_COLOR := Color("3ef2ff")

@export var prompt_text := "E: interactuar"
## Posición del aviso respecto al nodo.
@export var prompt_offset := Vector2(-40, -56)
@export var enabled := true:
	set(value):
		enabled = value
		_update_prompt()

var busy := false:
	set(value):
		busy = value
		_update_prompt()

var _player: Player
var _prompt: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt = Label.new()
	_prompt.text = prompt_text
	_prompt.position = prompt_offset
	# Fuente al doble escalada a la mitad: nítida con el zoom ×2 de la cámara.
	_prompt.scale = Vector2(0.5, 0.5)
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", PROMPT_COLOR)
	_prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_prompt.z_index = 10
	add_child(_prompt)
	_update_prompt()


## Jugador que está dentro del área (o null).
func get_player() -> Player:
	return _player


func _unhandled_input(event: InputEvent) -> void:
	if not _can_interact() or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	interacted.emit(_player)


func _can_interact() -> bool:
	return enabled and not busy and _player != null and not _player.controls_locked


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player = body
		_update_prompt()


func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_update_prompt()


func _process(_delta: float) -> void:
	# El aviso se oculta mientras Kai no puede moverse (cinemáticas, reaparición).
	if _prompt:
		_prompt.visible = _can_interact()


func _update_prompt() -> void:
	if _prompt:
		_prompt.text = prompt_text
		_prompt.visible = _can_interact()
