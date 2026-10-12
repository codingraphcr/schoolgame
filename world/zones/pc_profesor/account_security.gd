class_name AccountSecurity
extends Node
## Final de «La contraseña del profesor» (H4d). Lo inicia la pestaña de la cuenta (AccountTab) en el
## paso «elegir_seguridad»: Kai elige la nueva contraseña y el método de verificación en dos pasos
## (ChoiceWindow). Al terminar: diálogo, la Visión Digital queda desbloqueada (Q), el destello de la
## Nullblade se apaga, se completa la misión y Kai vuelve al laboratorio.
## Si cierra la ventana sin terminar, puede volver a intentarlo.

signal finished

const QUEST := &"contrasena_profesor"
const STEP := &"elegir_seguridad"

@export var challenge: ChoiceChallenge
@export var success_dialogue: Dialogue
## A dónde vuelve Kai al terminar (y por qué entrada).
@export_file("*.tscn") var exit_scene := "res://world/zones/zone0/pasillo_laboratorio.tscn"
@export var exit_entry: StringName = &"desde_pc"

var running := false


func start(player: Player) -> void:
	if running:
		return
	running = true
	player.controls_locked = true
	player.velocity.x = 0.0
	var window := ChoiceWindow.open(self, challenge)
	var completed: bool = await window.closed
	if not completed:
		player.controls_locked = false
		running = false
		return
	var game_state := get_node("/root/GameState")
	game_state.set_flag(&"cuenta_profesor_segura")
	var box := DialogueBox.find(self)
	if box and success_dialogue:
		await box.play(success_dialogue)
	game_state.unlock_vision()
	Sfx.play(&"reveal_flash")
	get_tree().call_group(&"toast", &"show_message",
		"Visión Digital desbloqueada: pulsa %s para ver lo oculto" % GameSettings.key_name(&"vision"), 4.0)
	_fade_nullblade(player)
	game_state.complete_step(QUEST, STEP)
	await get_tree().create_timer(2.2).timeout
	running = false
	finished.emit()
	get_node("/root/SceneManager").go_to_room(exit_scene, exit_entry)


## El destello de la Nullblade se apaga: Kai la perdió hasta encontrar la oficial (cuarto viejo, H5).
func _fade_nullblade(player: Player) -> void:
	if get_node("/root/GameState").nullblade_stage > 0:
		return
	player.combat.weapon = null
	Sfx.play(&"monitor_off")
