class_name SignalBridge
extends Node2D
## El puente inestable del Bosque de Fibra (Capítulo 3, «Contagio digital»), hijo de la sala. Sus plataformas
## (temporales) se deshacen al pisarlas: sin ayuda no se cruza. La primera vez que Kai se acerca (trigger_x), una señal
## azul desconocida lo estabiliza (las plataformas brillan en azul y ya no se deshacen) y el Grimorio muestra su aviso;
## Kai pregunta quién es, sin respuesta. Al llegar al otro lado (exit_x) se completa el paso: encontró otra salida.
## La señal no se nombra: es Aegis, pero el jugador todavía no lo sabe (gasta su energía en ayudar).

const BLUE := Color(0.55, 0.85, 1.35)
const STABLE_FLAG := &"puente_estabilizado"

@export var platforms: Array[NodePath] = []
@export var trigger_x := 200.0
@export var exit_x := 900.0
@export var alert_lines: PackedStringArray = ["RUTA ALTERNATIVA DISPONIBLE", "RIESGO DE CAÍDA: ELEVADO", "POR FAVOR, TEN CUIDADO"]
@export var ask_dialogue: Dialogue
@export var quest_id: StringName = &"contagio_digital"
@export var step_id: StringName = &"encontrar_salida"
@export var quick := false

var helping := false


func _ready() -> void:
	if _state().has_flag(STABLE_FLAG):
		_stabilize()


func _physics_process(_delta: float) -> void:
	var player := StoryHelper.room_player(self)
	if player == null:
		return
	var state := _state()
	if not state.has_flag(STABLE_FLAG) and not helping and player.global_position.x >= trigger_x:
		_help()
	elif state.has_flag(STABLE_FLAG) and state.get_current_step(quest_id) == step_id and player.global_position.x >= exit_x:
		state.complete_step(quest_id, step_id)


## La señal azul ayuda: estabiliza el puente, avisa y no responde.
func _help() -> void:
	helping = true
	_state().set_flag(STABLE_FLAG)
	_stabilize()
	Sfx.play(&"reveal_flash")
	GrimorioAlert.show_lines(self, alert_lines, 1.0 if quick else 3.5, GrimorioAlert.BLUE)
	await StoryHelper.say(self, ask_dialogue)
	helping = false


func _stabilize() -> void:
	for path in platforms:
		var platform := get_node_or_null(path) as DataPlatform
		if platform:
			platform.stabilized = true
			platform.modulate = BLUE


func _state() -> Node:
	return get_node("/root/GameState")
