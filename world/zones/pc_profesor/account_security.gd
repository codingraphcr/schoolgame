class_name AccountSecurity
extends Node
## Final de «La contraseña del profesor» (H4d). Lo inicia la pestaña de la cuenta (AccountTab) en el
## paso «elegir_seguridad»: el jugador CREA la nueva contraseña (PasswordWindow; se guarda solo su
## huella y tendrá que recordarla en el capítulo 4 y en misiones extra) y elige el método de
## verificación en dos pasos (ChoiceWindow). Al terminar: diálogo, la Visión Digital queda desbloqueada (Q), el destello de la
## Nullblade se apaga, se completa la misión y Kai vuelve al laboratorio.
## Si cierra la ventana sin terminar, puede volver a intentarlo.

signal finished

const QUEST := &"contrasena_profesor"
const STEP := &"elegir_seguridad"
## Id de la contraseña del profesor (GameState.check_password(PASSWORD_ID, intento)).
const PASSWORD_ID := &"profesor"

@export var challenge: ChoiceChallenge
@export var success_dialogue: Dialogue
## A dónde vuelve Kai al terminar (y por qué entrada).
@export_file("*.tscn") var exit_scene := "res://world/zones/zone0/laboratorio.tscn"
@export var exit_entry: StringName = &"desde_pc"

var running := false


func start(player: Player) -> void:
	if running:
		return
	running = true
	player.controls_locked = true
	player.velocity.x = 0.0
	var game_state := get_node("/root/GameState")
	# Si ya la creó (y cerró la ventana en el paso 2), no tiene que crearla otra vez.
	if not game_state.has_password(PASSWORD_ID):
		var create := PasswordWindow.open(self, PASSWORD_ID, "%s · Paso 1 de 2" % challenge.title)
		if not await create.closed:
			_cancel(player)
			return
	var window := ChoiceWindow.open(self, challenge, 1, 2)
	if not await window.closed:
		_cancel(player)
		return
	game_state.set_flag(&"cuenta_profesor_segura")
	var economy := get_node("/root/Economy")
	economy.claim_reward(StringName("desafio:%s" % challenge.id), economy.reward_for(EconomyConfig.Source.CHALLENGE, challenge.ecos_reward))
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


func _cancel(player: Player) -> void:
	player.controls_locked = false
	running = false


## El destello de la Nullblade se apaga: Kai la perdió hasta encontrar la oficial (cuarto viejo, H5).
func _fade_nullblade(player: Player) -> void:
	if get_node("/root/GameState").nullblade_stage > 0:
		return
	player.combat.weapon = null
	Sfx.play(&"monitor_off")
