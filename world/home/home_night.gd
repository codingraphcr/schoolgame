class_name HomeNight
extends Node
## La noche en el cuarto de Kai (Capítulo 1, «Camino a casa», paso descansar), hijo de la sala:
## 1. Kai se acuesta (KaiBed.rest_confirmed): fundido, Kai dormido en la cama, se recupera, marca
##    SLEEP_FLAG y la escena va a la sala, donde mamá y papá hablan a solas (HomeStory).
## 2. De vuelta en el cuarto (PARENTS_FLAG): la Resonancia Digital. Interferencias, una señal lejana y,
##    por un instante, datos de la computadora de Kai (ResonanceOverlay). Marca RESONANCE_FLAG (evento
##    narrativo provisional: no es una habilidad) y amanece.
## 3. Kai despierta confundido (wake_dialogue), se completa la misión («CAPÍTULO 2») y se guarda la
##    partida en la cama (cristales y energía llenos, como en un punto de guardado).
## Si una partida quedara a mitad (dormido sin la charla de los papás), Kai vuelve a estar despierto.

const QUEST := &"camino_a_casa"
const RESONANCE_FLAG := &"resonancia_digital_1"

@export var bed: KaiBed
@export var computer: KaiComputer
@export var resonance_lines: PackedStringArray = []
@export var wake_dialogue: Dialogue
@export_file("*.tscn") var house_scene := "res://world/zones/barrio/casa.tscn"
@export var house_entry: StringName = &"escena_noche"
@export var bed_entry: StringName = &"cama"
@export var quick := false

var busy := false


func _ready() -> void:
	bed.rest_confirmed.connect(go_to_sleep)
	_start.call_deferred()


func _start() -> void:
	await get_tree().process_frame
	var state := _state()
	if state.get_current_step(QUEST) != &"descansar":
		return
	if state.has_flag(HomeStory.SLEEP_FLAG) and state.has_flag(HomeStory.PARENTS_FLAG) and not state.has_flag(RESONANCE_FLAG):
		await resonance()
	elif state.has_flag(HomeStory.SLEEP_FLAG) and not state.has_flag(HomeStory.PARENTS_FLAG):
		state.clear_flag(HomeStory.SLEEP_FLAG)


## Kai se acuesta.
func go_to_sleep() -> void:
	if busy:
		return
	busy = true
	var player := _room().player
	player.controls_locked = true
	player.velocity.x = 0.0
	await _scenes().transition(func() -> void:
		player.visible = false
		bed.sleeping = true
		_restore(player))
	_state().set_flag(HomeStory.SLEEP_FLAG)
	await _wait(1.2)
	_scenes().go_to_room(house_scene, house_entry, &"casa")


## La Resonancia Digital y la mañana siguiente.
func resonance() -> void:
	busy = true
	var room := _room()
	var player := room.player
	player.controls_locked = true
	player.visible = false
	bed.sleeping = true
	var objective := room.get_node_or_null("CombatHUD/Objective") as CanvasItem
	if objective:
		objective.modulate.a = 0.0
	await _wait(1.6)
	computer.flicker = 1.0
	var overlay := ResonanceOverlay.play(self, resonance_lines, 0.2 if quick else 1.6)
	await overlay.finished
	computer.flicker = 0.0
	_state().set_flag(RESONANCE_FLAG)  # Ya es de mañana (DayPhase).
	await _scenes().transition(func() -> void:
		bed.sleeping = false
		player.visible = true
		player.global_position = bed.global_position + Vector2(-72, 0)
		player.face(1)
		_restore(player)
		if objective:
			objective.modulate.a = 1.0)
	await _wait(0.6)
	await StoryHelper.say(self, wake_dialogue)
	_state().complete_step(QUEST, &"descansar")
	_save()
	busy = false


func _restore(player: Player) -> void:
	player.health.restore_full()
	player.set_energy(player.max_energy)
	var state := _state()
	state.current_masks = -1.0
	state.current_energy = -1.0


## Guarda en la cama (como un punto de guardado), si hay una partida abierta.
func _save() -> void:
	var saves := get_node("/root/SaveManager")
	if saves.active_slot == 0:
		return
	var saved: bool = saves.save_game(_room().scene_file_path, bed_entry)
	get_tree().call_group(&"toast", &"show_message",
		"Partida guardada · cristales y energía llenos" if saved else "No se pudo guardar la partida", 2.5)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * (0.15 if quick else 1.0), false, true).timeout


func _room() -> Room:
	return get_parent() as Room


func _scenes() -> Node:
	return get_node("/root/SceneManager")


func _state() -> Node:
	return get_node("/root/GameState")
