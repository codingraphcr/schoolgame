class_name PasswordFight
extends Node2D
## Jefe del prólogo: la «Contraseña débil» (WeakPasswordBoss) en la cuenta del profesor. Lo inicia la
## pestaña «Cambiar contraseña» (AccountTab): aparece una ventanita "123456" que habla, decenas de
## ventanas de error forman el cuerpo del jefe, la Nullblade se materializa (J) como un **destello**
## (no queda obtenida; la oficial está en el cuarto viejo, H5), aparece su barra de vida y una barrera
## cierra la zona. Al ganar: sus ventanas muestran "ACCESO DENEGADO" y explotan, la Nullblade se
## deshace en la mano de Kai («¿A dónde se fue?»), no logra invocarla otra vez y recoge el primer
## fragmento de vida; después habla el profesor y se completa el paso «cambiar_contrasena».
## Si Kai muere, el combate se cancela (reaparece en el punto de restauración) y se puede repetir.

signal finished(won: bool)

const BOSS_SCENE := preload("res://characters/enemies/weak_password_boss/weak_password_boss.tscn")
## Flag del fragmento de vida que suelta el jefe (se recoge una sola vez).
const FRAGMENT_FLAG := &"fragmento_vida_contrasena_debil"
const QUEST := &"contrasena_profesor"
const STEP := &"cambiar_contrasena"

@export var weapon: WeaponData
@export var barrier: ArenaBarrier
## Peligros que solo funcionan durante la pelea (p. ej. una lluvia de correos SPAM sobre la arena).
@export var fight_hazards: Array[Node] = []
## Dónde aparece el enemigo.
@export var spawn_point: Marker2D
@export var intro_dialogue: Dialogue
## Diálogo corto al volver a intentarlo.
@export var retry_dialogue: Dialogue
@export var victory_dialogue: Dialogue
## Al vencer: la Nullblade se deshace («¿A dónde se fue?») y Kai no logra invocarla otra vez.
@export var blade_gone_dialogue: Dialogue = preload("res://data/dialogues/prologo/nullblade_desaparece.tres")
@export var blade_missing_dialogue: Dialogue = preload("res://data/dialogues/prologo/nullblade_no_vuelve.tres")

var enemy: EnemyBase
var running := false

var _player: Player
var _intro_seen := false
var _boss_bar: BossBar


func _ready() -> void:
	_set_hazards(false)


## Enciende o apaga los peligros de la arena (y quita los correos que quedaron cayendo).
func _set_hazards(on: bool) -> void:
	for hazard in fight_hazards:
		if hazard == null:
			continue
		hazard.set_process(on)
		if not on:
			for child in hazard.get_children():
				child.queue_free()


func start(player: Player) -> void:
	if running:
		return
	running = true
	_player = player
	player.controls_locked = true
	player.velocity.x = 0.0
	# Al principio es solo una ventanita "123456" que habla.
	var boss := BOSS_SCENE.instantiate() as WeakPasswordBoss
	enemy = boss
	enemy.ai_enabled = false
	get_parent().add_child(enemy)
	enemy.global_position = spawn_point.global_position
	enemy.scale = Vector2(0.1, 0.1)
	enemy.create_tween().tween_property(enemy, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play(&"popup_open")
	enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
	player.damage.died.connect(_on_player_died, CONNECT_ONE_SHOT)
	var first_time := not _intro_seen
	# La cámara va hacia el jefe (aparece al fondo de la arena) mientras habla y se arma.
	await _focus_camera(spawn_point.global_position + Vector2(-90, -40))
	var box := DialogueBox.find(self)
	var dialogue := retry_dialogue if _intro_seen and retry_dialogue else intro_dialogue
	if box and dialogue:
		await box.play(dialogue)
	_intro_seen = true
	if not running:
		return
	# Decenas de ventanas de error se abren, se juntan y forman el cuerpo del jefe.
	await boss.assemble(not first_time)
	await _focus_camera(player.global_position + Vector2(0, -24))
	_release_camera()
	if not running:
		return
	# La primera vez, la Nullblade se materializa frente a Kai: es un destello, sin la tarjeta de
	# equipamiento ni quedar obtenida (eso pasa con la Nullblade oficial, en el cuarto viejo).
	var game_state := get_node("/root/GameState")
	if game_state.nullblade_stage == 0 and not game_state.has_flag(&"nullblade_destello"):
		await NullbladeReveal.play(player, false)
		game_state.set_flag(&"nullblade_destello")
		if not running:
			return
	player.combat.weapon = weapon
	var hud := get_parent().get_node_or_null("CombatHUD")
	if hud:
		_boss_bar = BossBar.show_for(hud, enemy, "CONTRASEÑA DÉBIL")
	Music.play(&"pelea")
	if barrier:
		barrier.active = true
	_set_hazards(true)
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
	_set_hazards(false)
	if is_instance_valid(_boss_bar):
		_boss_bar.dismiss()
	if not won:
		enemy.queue_free()
		finished.emit(false)
		return
	_player.controls_locked = true
	_player.velocity.x = 0.0
	# Sus ventanas muestran "ACCESO DENEGADO" y explotan; el cuerpo se deshace en código.
	var drop := enemy.global_position + Vector2(0, -36)
	if enemy.has_signal(&"death_finished"):
		await enemy.death_finished
	# La Nullblade parpadea, Kai la aprieta y se deshace en partículas violetas.
	await NullbladeFade.play(_player)
	var box := DialogueBox.find(self)
	if box and blade_gone_dialogue:
		await box.play(blade_gone_dialogue)
	# Intenta invocarla otra vez... y no pasa nada.
	await NullbladeFade.try_summon(_player)
	if box and blade_missing_dialogue:
		await box.play(blade_missing_dialogue)
	# El jefe dejó el primer fragmento de vida: vuela hacia Kai.
	var game_state := get_node("/root/GameState")
	if not game_state.has_flag(FRAGMENT_FLAG):
		var fragment := LifeFragment.spawn(get_parent(), drop, FRAGMENT_FLAG)
		await get_tree().create_timer(0.6).timeout
		fragment.attract()
		await fragment.collected
		await get_tree().create_timer(0.8).timeout
	if box and victory_dialogue:
		await box.play(victory_dialogue)
	game_state.complete_step(QUEST, STEP)
	_player.controls_locked = false
	finished.emit(true)


## Lleva la cámara a un punto (deja de seguir a Kai hasta _release_camera()).
func _focus_camera(target: Vector2, seconds := 0.7) -> void:
	var camera := (get_parent() as Room).camera if get_parent() is Room else null
	if camera == null:
		return
	camera.target = null
	var tween := camera.create_tween()
	tween.tween_property(camera, "global_position", target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _release_camera() -> void:
	var camera := (get_parent() as Room).camera if get_parent() is Room else null
	if camera:
		camera.target = _player


## Texto de la tecla asignada a una acción (p. ej. "J"), para los avisos.
static func _key_for(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key:
			return key.as_text_physical_keycode() if key.physical_keycode != KEY_NONE else key.as_text_keycode()
	return String(action)
