extends Area2D
## Escena 3 del prólogo: Kai revisa un servidor extraño del laboratorio, aparece el mensaje
## "Por fin alguien está mirando", las luces parpadean y despierta su Visión Digital
## (la primera vez se enciende sola). Ocurre una sola vez: después GameState.vision_unlocked es true.

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")

@export var digital_world: DigitalWorld
## Nodo con las luces de la sala: parpadean durante el evento.
@export var lights: Node
@export var prompt_text := "E: revisar el servidor"
@export var message := "«Por fin alguien está mirando.»"
@export var hint := "Q: Visión Digital. Dura 10 s y luego se recarga."

var _player: Player
var _prompt: Label
var _running := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt = Label.new()
	_prompt.text = prompt_text
	_prompt.position = Vector2(-40, -52)
	# Fuente al doble escalada a la mitad: nítida con el zoom ×2 de la cámara.
	_prompt.scale = Vector2(0.5, 0.5)
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", CYAN)
	_prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_prompt.visible = false
	add_child(_prompt)


func _unhandled_input(event: InputEvent) -> void:
	if _player and not _running and not _already_awake() and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_awaken()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player = body
		_prompt.visible = not _already_awake() and not _running


func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_prompt.visible = false


func _awaken() -> void:
	_running = true
	_prompt.visible = false
	var player := _player
	player.controls_locked = true
	_toast(message, 3.5, MAG)
	# Las luces parpadean y la pantalla se corrompe.
	for i in 6:
		_set_lights(i % 2 == 1)
		if digital_world and i % 2 == 0:
			digital_world.pulse_glitch(0.5)
		await get_tree().create_timer(0.12 + 0.04 * (i % 3)).timeout
	_set_lights(true)
	await get_tree().create_timer(0.5).timeout
	# Primera Visión Digital: se enciende sola.
	get_node("/root/GameState").unlock_vision()
	get_node("/root/DigitalVision").activate(true)
	await get_tree().create_timer(1.2).timeout
	_toast(hint, 4.0, CYAN)
	player.controls_locked = false
	_running = false


func _set_lights(on: bool) -> void:
	if lights == null:
		return
	for light in lights.get_children():
		if light is CanvasItem:
			light.visible = on


func _already_awake() -> bool:
	return get_node("/root/GameState").vision_unlocked


func _toast(text: String, seconds: float, color: Color) -> void:
	get_tree().call_group(&"toast", &"show_message", text, seconds, color)
