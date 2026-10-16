class_name AegisEncounter
extends Node
## La historia de Aegis en el núcleo de la Estación Lázaro (Capítulo 3, Nivel 6), hijo de la sala:
## 1. encontrar_aegis: Kai encuentra la esferita dañada en el piso: era la señal azul (encounter_dialogue). Empieza la
##    misión especial «Eco en la Red» (restablecer la energía, recuperar los módulos, estabilizar el núcleo).
## 2. Cuando el núcleo se estabiliza (CoreDefense.finished), Aegis se eleva; «Eco en la Red» queda completa.
## 3. decision: Aegis elige acompañar a Kai (decision_dialogue): es una invitación, no una orden. Aegis pasa a ser su
##    compañero (aegis_stage 1 = Aegis Pulse, marca AegisCompanion.FLAG), la estación activa la alarma y hay que escapar.
## Si la partida se guardó a mitad, al volver sigue desde donde quedó.

const QUEST := &"la_senal_perdida"
const ECO := &"eco_en_la_red"

@export var aegis_body: AegisBody
@export var core: CoreDefense
@export var encounter_dialogue: Dialogue
@export var decision_dialogue: Dialogue
@export var alarm_dialogue: Dialogue

var playing := false


func _ready() -> void:
	if core:
		core.finished.connect(_on_core_stable)
	_refresh_body()
	_resume.call_deferred()


func _refresh_body() -> void:
	if aegis_body == null:
		return
	var state := _state()
	var repaired: bool = state.has_flag(CoreDefense.STABLE_FLAG)
	aegis_body.mood = AegisBody.Mood.FLOTANDO if repaired else AegisBody.Mood.DANADO
	aegis_body.power = 1.0 if repaired else 0.25
	aegis_body.position.y = -40.0 if repaired else -8.0
	# Ya es su compañero: lo dibuja AegisCompanion junto a Kai.
	aegis_body.visible = not AegisCompanion.is_active(state)


func _resume() -> void:
	await get_tree().process_frame
	var step: StringName = _state().get_current_step(QUEST)
	if step == &"encontrar_aegis":
		await _encounter()
	elif step == &"decision":
		await _decision()


func _encounter() -> void:
	playing = true
	await StoryHelper.say(self, encounter_dialogue)
	var state := _state()
	state.complete_step(QUEST, &"encontrar_aegis")
	state.start_quest(ECO)
	playing = false


func _on_core_stable() -> void:
	_refresh_body()
	var state := _state()
	if state.get_current_step(QUEST) == &"reparar_aegis":
		state.complete_step(QUEST, &"reparar_aegis")
	await _decision()


func _decision() -> void:
	playing = true
	var state := _state()
	await StoryHelper.say(self, decision_dialogue)
	state.set_aegis_stage(1)
	state.set_flag(AegisCompanion.FLAG)
	state.set_flag(LazaroPropsFlags.ALARM)
	_refresh_body()
	var room := _room()
	if room and room.has_method(&"spawn_companion"):
		room.spawn_companion()
	await StoryHelper.say(self, alarm_dialogue)
	get_tree().call_group(&"toast", &"show_message", "Aegis Pulse · tecla %s: dispara al objetivo más cercano" % GameSettings.key_name(&"aegis_fire"), 4.0)
	state.complete_step(QUEST, &"decision")
	playing = false


func _room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room


func _state() -> Node:
	return get_node("/root/GameState")
