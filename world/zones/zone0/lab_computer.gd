extends Interactable
## La computadora del laboratorio (escena 3 del prólogo). Mientras el prólogo pide revisarla:
## la pantalla se enciende sola («Por fin alguien está mirando»), las luces parpadean y la Visión
## Digital se activa sola unos segundos, como un glitch que Kai no controla. Después Kai reacciona
## y la misión avanza. En la misión del profesor, Kai es absorbido por la pantalla (DigitalDive),
## pasa por una pantalla de carga y aparece dentro de la computadora como alma digital.

const CYAN := Color("3ef2ff")
const PC_SCENE := "res://world/zones/pc_profesor/escritorio.tscn"
const LOADING_LINES: PackedStringArray = [
	"Digitalizando a Kai...",
	"Abriendo la cuenta: profesor@colegio",
	"Contraseña detectada: ******  (débil)",
	"Cargando escritorio...",
]

@export var digital_world: DigitalWorld
## Nodo con las luces de la sala: parpadean durante el evento.
@export var lights: Node
## Lo que muestra la pantalla al encenderse sola.
@export var screen_dialogue: Dialogue
## La reacción de Kai cuando termina la visión.
@export var after_dialogue: Dialogue
## Segundos que dura la primera visión involuntaria.
@export var glitch_seconds := 4.0
## Punto de la pantalla que absorbe a Kai (coordenadas del mundo).
@export var screen_point := Vector2(714, 262)
## Monitor de pared: se enciende solo, muestra a la entidad («???») y se apaga.
@export var monitor: LabMonitor
## Segundos de interferencia en el monitor antes del mensaje.
@export var static_seconds := 0.9
## Segundos que el monitor queda apagado después del mensaje.
@export var monitor_off_seconds := 0.8


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)
	_refresh()
	# El monitor está apagado hasta que se enciende solo; después queda con la pantalla normal.
	if monitor:
		var step: StringName = get_node("/root/GameState").get_current_step(&"prologo")
		var before_event := step in [&"hablar_profesor", &"revisar_computadora"]
		monitor.switch_to(LabMonitor.State.OFF if before_event else LabMonitor.State.IDLE)


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
	elif game_state.get_current_step(&"contrasena_profesor") in [&"cruzar_spam", &"revisar_configuracion", &"cambiar_contrasena"]:
		# Kai salió de la computadora antes de terminar: puede volver a entrar.
		prompt_text = "E: volver a la computadora"
		enabled = true
	else:
		enabled = false


func _on_interacted(player: Player) -> void:
	var game_state := get_node("/root/GameState")
	if game_state.get_current_step(&"prologo") == &"revisar_computadora":
		await _first_glitch(player)
	else:
		await _enter_computer(player)


func _first_glitch(player: Player) -> void:
	busy = true
	player.controls_locked = true
	player.velocity.x = 0.0
	var box := DialogueBox.find(self)
	# El monitor se enciende solo y se llena de interferencia antes del mensaje.
	if monitor:
		if digital_world:
			digital_world.pulse_glitch(0.35)
		await monitor.power_on_with_static(static_seconds)
	if box and screen_dialogue:
		var lines := screen_dialogue.get_lines()
		var on_line := func(index: int) -> void: _on_screen_line(lines[index])
		box.line_started.connect(on_line)
		await box.play(screen_dialogue)
		box.line_started.disconnect(on_line)
	# Después del mensaje el monitor parpadea y se apaga un momento.
	if monitor:
		if digital_world:
			digital_world.pulse_glitch(0.5)
		await monitor.flicker_off()
		await get_tree().create_timer(monitor_off_seconds).timeout
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
	if monitor:
		monitor.switch_to(LabMonitor.State.IDLE)
	await get_tree().create_timer(0.4).timeout
	if box and after_dialogue:
		await box.play(after_dialogue)
	get_node("/root/GameState").complete_step(&"prologo", &"revisar_computadora")
	player.controls_locked = false
	await get_tree().process_frame
	busy = false


## Kai es absorbido por la pantalla y entra a la computadora del profesor.
func _enter_computer(player: Player) -> void:
	busy = true
	player.controls_locked = true
	player.velocity = Vector2.ZERO
	var room := owner as Room
	await DigitalDive.dive(player, screen_point, room.camera if room else null)
	await LoadingScreen.show_loading(self, "CONECTANDO...", LOADING_LINES, 2.8)
	get_node("/root/SceneManager").go_to_room(PC_SCENE, &"inicio")


## Lo que muestra el monitor en cada línea: el cursor con la narración y el ojo cuando habla «???».
func _on_screen_line(line: Dictionary) -> void:
	if monitor == null:
		return
	if String(line["speaker"]).is_empty():
		monitor.switch_to(LabMonitor.State.IDLE)
	elif monitor.state != LabMonitor.State.EYE:
		monitor.show_eye()


func _set_lights(on: bool) -> void:
	if lights == null:
		return
	for light in lights.get_children():
		if light is CanvasItem:
			light.visible = on
