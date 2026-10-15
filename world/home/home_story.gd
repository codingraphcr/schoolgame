class_name HomeStory
extends Node
## La historia en la casa de Kai (Capítulo 1, misión «Camino a casa»), hijo de la sala:
## - Al llegar (paso volver_a_casa), se completa el paso: Kai está en casa.
## - Paso hablar_familia: cuando Kai entra a la sala, mamá viene de la cocina y hablan (mom_dialogue);
##   papá se levanta del sofá y se acerca (dad_dialogue). Fundido: «Más tarde, después de la cena...»
##   y es de noche (paso descansar: los dos se van a su rutina de la noche).
## - Mientras Kai duerme (lo manda HomeNight con la marca SLEEP_FLAG): Kai no está, la cámara mira a
##   los papás y hablan a solas (parents_dialogue, una pista: no se explica nada). Después, vuelve al
##   cuarto (HomeNight sigue con la Resonancia Digital).
## Los papás conocen parte del origen de Kai (Biblia Narrativa, sección 5): aquí solo se nota en miradas
## y frases con doble sentido.

const QUEST := &"camino_a_casa"
const FAMILY_FLAG := &"cap1_charla_familiar"
const SLEEP_FLAG := &"cap1_kai_dormido"
const PARENTS_FLAG := &"cap1_padres_hablaron"

@export var mom: FamilyMember
@export var dad: FamilyMember
## Desde dónde (x) empieza la charla familiar al entrar a la sala.
@export var family_trigger_x := 250.0
@export var mom_dialogue: Dialogue
@export var dad_dialogue: Dialogue
@export var parents_dialogue: Dialogue
@export var later_caption := "Más tarde, después de la cena..."
@export var night_caption := "Mientras tanto, en la sala..."
@export_file("*.tscn") var bedroom_scene := "res://world/zones/barrio/cuarto_kai.tscn"
@export var bedroom_entry: StringName = &"cama"
## En las pruebas: esperas cortas.
@export var quick := false

var busy := false


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	await get_tree().process_frame
	var state := _state()
	if state.get_current_step(QUEST) == &"volver_a_casa":
		state.complete_step(QUEST, &"volver_a_casa")
	if state.get_current_step(QUEST) == &"descansar" and state.has_flag(SLEEP_FLAG) and not state.has_flag(PARENTS_FLAG):
		await parents_at_night()


func _physics_process(_delta: float) -> void:
	if busy or _state().get_current_step(QUEST) != &"hablar_familia":
		return
	var player := _room().player
	if player == null or player.controls_locked:
		return
	if player.global_position.x >= family_trigger_x:
		family_talk()


## La primera charla con mamá y papá.
func family_talk() -> void:
	busy = true
	var room := _room()
	var player := room.player
	player.controls_locked = true
	player.velocity.x = 0.0
	player.face(1)
	var kai_x := player.global_position.x
	await _walk(mom, kai_x + 64.0)
	await _say(mom_dialogue)
	await _walk(dad, kai_x + 34.0)
	await _say(dad_dialogue)
	_state().set_flag(FAMILY_FLAG)
	var caption := [null]
	await _scenes().transition(func() -> void:
		_state().complete_step(QUEST, &"hablar_familia")
		mom.apply_routine(true)
		dad.apply_routine(true)
		caption[0] = _show_caption(later_caption))
	await _wait(2.2)
	if is_instance_valid(caption[0]):
		caption[0].queue_free()
	player.controls_locked = false
	busy = false


## Kai duerme; mamá y papá hablan a solas en la sala.
func parents_at_night() -> void:
	busy = true
	var room := _room()
	var player := room.player
	player.controls_locked = true
	player.visible = false
	var objective := room.get_node_or_null("CombatHUD/Objective") as CanvasItem
	if objective:
		objective.modulate.a = 0.0  # Es una escena aparte: sin el objetivo de Kai.
	room.camera.target = null
	room.camera.global_position = (mom.global_position + dad.global_position) / 2.0 + Vector2(0, -40)
	var caption := _show_caption(night_caption)
	await _wait(2.4)
	if is_instance_valid(caption):
		caption.queue_free()
	await _say(parents_dialogue)
	_state().set_flag(PARENTS_FLAG)
	await _wait(0.8)
	_scenes().go_to_room(bedroom_scene, bedroom_entry, &"cuarto_kai")


func _walk(member: FamilyMember, x: float) -> void:
	var distance := absf(member.global_position.x - x)
	if distance < 2.0:
		return
	member.get_node("Sprite").flip_h = x < member.global_position.x
	var tween := member.create_tween()
	tween.tween_property(member, "global_position:x", x, distance / (400.0 if quick else 90.0))
	await tween.finished
	member.get_node("Sprite").flip_h = true  # Mira a Kai (a su izquierda).


## Un diálogo sin devolver el control (la escena sigue).
func _say(dialogue: Dialogue) -> void:
	var box := DialogueBox.find(self)
	if dialogue and box:
		await box.play(dialogue)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * (0.15 if quick else 1.0), false, true).timeout


func _show_caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 22)
	label.add_theme_color_override(&"font_color", Color(1.0, 0.92, 0.8))
	label.add_theme_color_override(&"font_outline_color", Color(0.05, 0.03, 0.02))
	label.add_theme_constant_override(&"outline_size", 6)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = -90.0
	label.offset_bottom = -60.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room().get_node("CombatHUD").add_child(label)
	return label


func _room() -> Room:
	return get_parent() as Room


func _scenes() -> Node:
	return get_node("/root/SceneManager")


func _state() -> Node:
	return get_node("/root/GameState")
