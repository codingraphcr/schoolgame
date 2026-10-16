class_name ForestExitScene
extends Node
## Kai y Aegis salen de la Estación Lázaro al Bosque de Fibra (Capítulo 3), hijo de la sala. Si la partida está en
## step_id de quest_id: Aegis mira el bosque por primera vez (colors_dialogue), una escena cómica (fall_joke_dialogue)
## y el paso se completa. La estación se calma (se apaga la alarma: se puede volver a visitar). Desde ahí el bosque tiene salida (EXIT_FLAG): la troncal del claro lleva al colegio.

const EXIT_FLAG := &"bosque_salida_abierta"

@export var colors_dialogue: Dialogue
@export var fall_joke_dialogue: Dialogue
@export var quest_id: StringName = &"la_senal_perdida"
@export var step_id: StringName = &"escapar"

var playing := false


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	await get_tree().process_frame
	var state := get_node("/root/GameState")
	if state.get_current_step(quest_id) != step_id:
		return
	playing = true
	state.set_flag(LazaroPropsFlags.ESCAPED)
	state.clear_flag(LazaroPropsFlags.ALARM)
	await StoryHelper.say(self, colors_dialogue)
	await StoryHelper.say(self, fall_joke_dialogue)
	state.set_flag(EXIT_FLAG)
	state.complete_step(quest_id, step_id)
	playing = false
