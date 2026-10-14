extends Node
## El cuarto viejo (H5, misión «El cuarto viejo»). Está a oscuras: con la Visión Digital Kai distingue
## la Nullblade oficial y el Grimorio (HiddenRelic). La Nullblade trae el dash (el doble salto llega
## más adelante en la historia, para no facilitar tanto la exploración); el Grimorio se puede abrir
## con G desde entonces. Con las dos, el piso cerca de la puerta se corrompe (pinchos): para salir
## hay que cruzarlo con salto + dash (o rebotando en los pinchos con la Nullblade).
## Al volver a la sala, todo queda como se dejó (marcas de GameState y el paso de la misión).

const QUEST := &"cuarto_viejo"
const ARRIVED_FLAG := &"cuarto_viejo_visto"

@export var player: Player
@export var nullblade: HiddenRelic
@export var grimorio: HiddenRelic
## El piso corrupto: aparece con el derrumbe.
@export var spikes: Spikes
@export var arrival_dialogue: Dialogue
@export var nullblade_dialogue: Dialogue
@export var grimorio_dialogue: Dialogue
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
	nullblade.taken.connect(_on_nullblade_taken)
	grimorio.taken.connect(_on_grimorio_taken)
	_set_blocked(_game_state().has_reached_step(QUEST, &"salir_cuarto"))
	if not _game_state().has_flag(ARRIVED_FLAG):
		_arrive.call_deferred()


func _arrive() -> void:
	_game_state().set_flag(ARRIVED_FLAG)
	await _say(arrival_dialogue)
	_toast("Pulsa %s para usar la Visión Digital" % GameSettings.key_name(&"vision"))


func _on_nullblade_taken(by: Player) -> void:
	by.controls_locked = true
	by.velocity = Vector2.ZERO
	await NullbladeReveal.play(by)
	var state := _game_state()
	state.set_nullblade_stage(1)
	state.set_dash_level(1)
	by.apply_progress(state)
	await _say(nullblade_dialogue, false)
	_toast("Nueva habilidad: dash (%s)" % GameSettings.key_name(&"dash"), 5.0)
	by.controls_locked = false
	_check_both()


func _on_grimorio_taken(by: Player) -> void:
	by.controls_locked = true
	by.velocity = Vector2.ZERO
	_game_state().set_flag(GameState.GRIMORIO_FLAG)
	Sfx.play(&"reveal_flash")
	await _say(grimorio_dialogue, false)
	_toast("Encontraste el Grimorio: pulsa %s para abrirlo" % GameSettings.key_name(&"grimorio"), 5.0)
	by.controls_locked = false
	_check_both()


## Con la Nullblade y el Grimorio, el piso cerca de la puerta se corrompe.
func _check_both() -> void:
	if not (nullblade.is_taken() and grimorio.is_taken()) or _game_state().get_current_step(QUEST) != &"explorar_cuarto":
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
