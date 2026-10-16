extends Node
## El cuarto viejo (H5, misión «El cuarto viejo»). Está a oscuras: con la Visión Digital Kai distingue el
## Grimorio (HiddenRelic). Al tomarlo empieza la cinemática «El legado olvidado» (LegacyCinematic, storyboard
## de Ariel): el libro despierta, detecta la Nullblade al otro lado del cuarto (blade_point) y Kai la
## recupera. La Nullblade trae el dash (el doble salto se consigue más adelante); el Grimorio se puede abrir
## con G desde entonces. Con los dos, el piso cerca de la puerta se corrompe (pinchos) y cae un armario: para
## salir hay que saltar el armario y cruzar el piso corrupto con salto + dash.
## Al volver a la sala, todo queda como se dejó (marcas de GameState y el paso de la misión).

const QUEST := &"cuarto_viejo"
const ARRIVED_FLAG := &"cuarto_viejo_visto"
## Marca de la Nullblade recuperada aquí (la usaban las partidas viejas, cuando se tomaba aparte).
const BLADE_FLAG := &"nullblade_tomada"

@export var player: Player
@export var grimorio: HiddenRelic
## Donde se forma la Nullblade (su centro: sobre la caja del otro lado del cuarto).
@export var blade_point: Marker2D
## El piso corrupto y el armario caído: aparecen con el derrumbe.
@export var spikes: Spikes
@export var cabinet: StaticBody2D
@export var arrival_dialogue: Dialogue
## Solo el Grimorio (partidas viejas en las que la Nullblade ya se tenía).
@export var grimorio_dialogue: Dialogue
## Después de la cinemática completa (el libro y la espada).
@export var legacy_dialogue: Dialogue
@export var collapse_dialogue: Dialogue


func _ready() -> void:
	# Está tan oscuro que solo se distingue a Kai, con un brillo tenue.
	var glow := PointLight2D.new()
	glow.name = "DarkRoomGlow"
	glow.texture = load("res://assets/art/light_soft.tres")
	glow.texture_scale = 0.9
	glow.energy = 0.55
	glow.color = Color(0.7, 0.8, 1.0)
	glow.position = Vector2(0, -16)
	player.add_child(glow)
	grimorio.taken.connect(_on_grimorio_taken)
	_set_blocked(_game_state().has_reached_step(QUEST, &"salir_cuarto"))
	if not _game_state().has_flag(ARRIVED_FLAG):
		_arrive.call_deferred()
	elif _game_state().has_grimorio() and not _has_blade():
		# Partida vieja: tomó el Grimorio antes de que la espada saliera en la cinemática.
		_recover_blade.call_deferred()


func _arrive() -> void:
	_game_state().set_flag(ARRIVED_FLAG)
	await _say(arrival_dialogue)
	_toast("Pulsa %s para usar la Visión Digital" % GameSettings.key_name(&"vision"))


func _on_grimorio_taken(by: Player) -> void:
	by.controls_locked = true
	by.velocity = Vector2.ZERO
	var state := _game_state()
	state.set_flag(GameState.GRIMORIO_FLAG)
	var with_blade := not _has_blade()
	# El libro está apoyado en la mesa (lift) y la espada se forma sobre la caja de la derecha (blade_point).
	await LegacyCinematic.play(by, grimorio.global_position + Vector2(0, -grimorio.lift - 26.0 - LegacyCinematic.REST_Y), blade_point.global_position, with_blade)
	if with_blade:
		_give_blade(by)
	await _say(legacy_dialogue if with_blade else grimorio_dialogue, false)
	_toast("Grimorio: pulsa %s para abrirlo" % GameSettings.key_name(&"grimorio"), 4.0)
	if with_blade:
		await get_tree().create_timer(1.2).timeout
		_toast("Nueva habilidad: dash (%s; también en el aire)" % GameSettings.key_name(&"dash"), 5.0)
	by.controls_locked = false
	_check_both()


func _recover_blade() -> void:
	player.controls_locked = true
	player.velocity = Vector2.ZERO
	await NullbladeReveal.play(player, false, blade_point.global_position)
	await LegacyCinematic.nullblade_card(self)
	_give_blade(player)
	_toast("Nueva habilidad: dash (%s; también en el aire)" % GameSettings.key_name(&"dash"), 5.0)
	player.controls_locked = false
	_check_both()


func _give_blade(by: Player) -> void:
	var state := _game_state()
	state.set_flag(BLADE_FLAG)
	state.set_nullblade_stage(1)
	state.set_dash_level(1)
	by.apply_progress(state)


func _has_blade() -> bool:
	return _game_state().nullblade_stage >= 1


## Con la Nullblade y el Grimorio, el cuarto se corrompe y bloquea el camino a la puerta.
func _check_both() -> void:
	if not (_has_blade() and grimorio.is_taken()) or _game_state().get_current_step(QUEST) != &"explorar_cuarto":
		return
	player.controls_locked = true
	var room := owner as Room
	if room and room.camera:
		room.camera.shake(5.0, 0.8)
	Sfx.play(&"error")
	_set_blocked(true)
	await get_tree().create_timer(0.5).timeout
	await _say(collapse_dialogue, false)
	player.controls_locked = false
	_game_state().complete_step(QUEST, &"explorar_cuarto")


func _set_blocked(on: bool) -> void:
	spikes.visible = on
	spikes.set_deferred("monitorable", on)
	spikes.set_deferred("monitoring", on)
	cabinet.visible = on
	for child in cabinet.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not on)


func _say(dialogue: Dialogue, lock := true) -> void:
	var box := DialogueBox.find(self)
	if dialogue == null or box == null:
		return
	if lock:
		player.controls_locked = true
		player.velocity.x = 0.0
	await box.play(dialogue)
	if lock:
		player.controls_locked = false


func _toast(text: String, seconds := 4.0) -> void:
	get_tree().call_group(&"toast", &"show_message", text, seconds)


func _game_state() -> Node:
	return get_node("/root/GameState")
