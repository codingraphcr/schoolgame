class_name ProcessRoom
extends Node
## Sala de los procesos repetidos (Capítulo 2, nivel 4, paso «procesos»): el generador crea enemigos sin
## parar. Kai lee el registro en la terminal (la lista de procesos) y después elige cómo manejar el
## error (desafío): el ciclo se corta, los procesos se deshacen y se abre la puerta.

const QUEST := &"codigo_fuera_de_control"
const STEP := &"procesos"

@export var spawner: ProcessSpawner
@export var terminal: TerminalStation
@export var error_challenge: ChoiceChallenge
@export var gate: ArenaBarrier
@export var fixed_dialogue: Dialogue

var _busy := false


func _ready() -> void:
	terminal.solved.connect(_on_log_read)
	var state := get_node("/root/GameState")
	if state.has_reached_step(QUEST, STEP) and state.get_current_step(QUEST) != STEP:
		# Ya se corrigió: el ciclo sigue detenido.
		spawner.running = false
		gate.active = false
	else:
		gate.active = true


func _on_log_read() -> void:
	if _busy or get_node("/root/GameState").get_current_step(QUEST) != STEP:
		return
	_busy = true
	await StoryHelper.choose_until_done(self, error_challenge)
	spawner.stop()
	gate.active = false
	if fixed_dialogue:
		await StoryHelper.say(self, fixed_dialogue)
	get_node("/root/GameState").complete_step(QUEST, STEP)
	get_tree().call_group(&"toast", &"show_message", "Ciclo cortado: la puerta del núcleo se abrió.", 2.6)
	_busy = false
