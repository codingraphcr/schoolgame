class_name PasswordFight
extends Node2D
## Combate contra la «Contraseña débil» en la cuenta del profesor (H4c). Lo inicia la pestaña
## «Cambiar contraseña» (AccountTab): aparece el enemigo, habla, la Nullblade se materializa (J)
## y una barrera cierra la zona. Al ganar se completa el paso «cambiar_contrasena».
## Si Kai muere, el combate se cancela (reaparece en el punto de restauración) y se puede repetir.

signal finished(won: bool)

const ENEMY_SCENE := preload("res://characters/enemies/weak_password/weak_password.tscn")
const QUEST := &"contrasena_profesor"
const STEP := &"cambiar_contrasena"

@export var weapon: WeaponData
@export var barrier: ArenaBarrier
## Dónde aparece el enemigo.
@export var spawn_point: Marker2D
@export var intro_dialogue: Dialogue
## Diálogo corto al volver a intentarlo.
@export var retry_dialogue: Dialogue
@export var victory_dialogue: Dialogue

var enemy: EnemyBase
var running := false

var _player: Player
var _intro_seen := false


func start(player: Player) -> void:
	if running:
		return
	running = true
	_player = player
	player.controls_locked = true
	player.velocity.x = 0.0
	enemy = ENEMY_SCENE.instantiate()
	enemy.ai_enabled = false
	get_parent().add_child(enemy)
	enemy.global_position = spawn_point.global_position
	enemy.scale = Vector2(0.1, 0.1)
	enemy.create_tween().tween_property(enemy, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
	player.damage.died.connect(_on_player_died, CONNECT_ONE_SHOT)
	var box := DialogueBox.find(self)
	var dialogue := retry_dialogue if _intro_seen and retry_dialogue else intro_dialogue
	if box and dialogue:
		await box.play(dialogue)
	_intro_seen = true
	if not running:
		return
	# La primera vez, la Nullblade se materializa frente a Kai y aparece la tarjeta de equipamiento.
	var game_state := get_node("/root/GameState")
	if game_state.nullblade_stage == 0:
		await NullbladeReveal.play(player)
		game_state.set_nullblade_stage(1)
		if not running:
			return
	player.combat.weapon = weapon
	Music.play(&"pelea")
	if barrier:
		barrier.active = true
	get_tree().call_group(&"toast", &"show_message", "%s: pulsa %s para atacar" % [weapon.display_name, _key_for(&"attack")], 4.0)
	player.controls_locked = false
	enemy.ai_enabled = true


func _on_enemy_died() -> void:
	_end(true)


func _on_player_died() -> void:
	_end(false)


func _end(won: bool) -> void:
	if not running:
		return
	running = false
	Music.play(&"computadora")
	if enemy.died.is_connected(_on_enemy_died):
		enemy.died.disconnect(_on_enemy_died)
	if _player.damage.died.is_connected(_on_player_died):
		_player.damage.died.disconnect(_on_player_died)
	if barrier:
		barrier.active = false
	if not won:
		enemy.queue_free()
		finished.emit(false)
		return
	_player.controls_locked = true
	_player.velocity.x = 0.0
	await get_tree().create_timer(0.9).timeout
	var box := DialogueBox.find(self)
	if box and victory_dialogue:
		await box.play(victory_dialogue)
	get_node("/root/GameState").complete_step(QUEST, STEP)
	_player.controls_locked = false
	finished.emit(true)


## Texto de la tecla asignada a una acción (p. ej. "J"), para los avisos.
static func _key_for(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key:
			return key.as_text_physical_keycode() if key.physical_keycode != KEY_NONE else key.as_text_keycode()
	return String(action)
