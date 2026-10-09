extends Interactable
## La computadora del laboratorio (escena 3 del prólogo). Mientras el prólogo pide revisarla:
## la pantalla se enciende sola («Por fin alguien está mirando»), las luces parpadean y la Visión
## Digital se activa sola unos segundos, como un glitch que Kai no controla. Después Kai reacciona
## y la misión avanza. En la misión del profesor, aquí Kai entrará a la computadora (tarea H4).

const CYAN := Color("3ef2ff")

@export var digital_world: DigitalWorld
## Nodo con las luces de la sala: parpadean durante el evento.
@export var lights: Node
## Lo que muestra la pantalla al encenderse sola.
@export var screen_dialogue: Dialogue
## La reacción de Kai cuando termina la visión.
@export var after_dialogue: Dialogue
## Segundos que dura la primera visión involuntaria.
@export var glitch_seconds := 4.0


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)
	_refresh()


func _process(delta: float) -> void:
	_refresh()
	super(delta)


## Solo se puede usar cuando la historia lo pide.
func _refresh() -> void:
	var game_state := get_node("/root/GameState")
	if game_state.get_current_step(&"prologo") == &"revisar_computadora":
		prompt_text = "E: revisar la computadora"
		enabled = true
	elif game_state.get_current_step(&"contrasena_profesor") == &"entrar_pc":
		prompt_text = "E: revisar la cuenta del profesor"
		enabled = true
	else:
		enabled = false


func _on_interacted(player: Player) -> void:
	var game_state := get_node("/root/GameState")
	if game_state.get_current_step(&"prologo") == &"revisar_computadora":
		await _first_glitch(player)
	else:
		# Provisional hasta la tarea H4 (el nivel dentro de la computadora).
		get_tree().call_group(&"toast", &"show_message",
			"Próximamente: Kai entrará a la computadora como alma digital (tarea H4).", 4.0, CYAN)


func _first_glitch(player: Player) -> void:
	busy = true
	player.controls_locked = true
	player.velocity.x = 0.0
	var box := DialogueBox.find(self)
	if box and screen_dialogue:
		await box.play(screen_dialogue)
	# Las luces parpadean y la pantalla se corrompe.
	for i in 6:
		_set_lights(i % 2 == 1)
		if digital_world and i % 2 == 0:
			digital_world.pulse_glitch(0.5)
		await get_tree().create_timer(0.12 + 0.04 * (i % 3)).timeout
	_set_lights(true)
	# La Visión Digital se activa sola: Kai todavía no sabe qué es ni cómo usarla.
	var vision := get_node("/root/DigitalVision")
	vision.glitch(glitch_seconds)
	await vision.deactivated
	if digital_world:
		digital_world.pulse_glitch(0.6)
	await get_tree().create_timer(0.4).timeout
	if box and after_dialogue:
		await box.play(after_dialogue)
	get_node("/root/GameState").complete_step(&"prologo", &"revisar_computadora")
	player.controls_locked = false
	await get_tree().process_frame
	busy = false


func _set_lights(on: bool) -> void:
	if lights == null:
		return
	for light in lights.get_children():
		if light is CanvasItem:
			light.visible = on
