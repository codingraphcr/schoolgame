class_name TechRoomStory
extends Node
## Capítulo 1 en el cuarto técnico.
## - Escena 2.1 (paso revisar_servidor, al llegar): el servidor en rojo; Chip y Glitch se ríen desde
##   el monitor y se meten en la computadora. Después aparece la conexión (Inmersión Digital).
## - Escena 2.7 (paso hablar_profesor): Kai vuelve de la red y habla con el profesor. Kai se va y, como
##   escena aparte (opción A, decisión del equipo del 14 de octubre de 2026): fundido a negro, «Mientras
##   tanto...», el profesor solo frente al monitor ve aparecer GENESIS_ARCHIVE (no se explica qué es:
##   Biblia) y «FIN DEL CAPÍTULO 1» sobre esa imagen. Después Kai aparece en la entrada del colegio (no
##   vuelve al cuarto: él no vio nada).
## El servidor deja de estar en rojo cuando Chip y Glitch quedaron neutralizados.

const QUEST := &"travesuras_en_el_sistema"
const ENDING_FLAG := &"cap1_genesis_visto"

@export var chip: SiblingActor
@export var glitch: SiblingActor
@export var props: Node2D
@export var monitor_point := Vector2(470, 252)
@export var server_dialogue: Dialogue
## El profesor (Npc): su conversación del paso hablar_profesor no completa el paso; lo completa el final.
@export var profesor: Npc
## Hacia dónde se va Kai al terminar de hablar (antes de la salida: no cambia de sala).
@export var leave_point := Vector2(596, 304)
## Lo que se ve del profesor, solo, cuando aparece GENESIS_ARCHIVE (sin explicar qué es).
@export var genesis_dialogue: Dialogue
## Dónde aparece Kai después del final (no vuelve al cuarto técnico).
@export_file("*.tscn") var after_scene := "res://world/zones/zone0/entrada.tscn"
@export var after_entry: StringName = &"desde_pasillo"
@export var after_room: StringName = &"entrada"
## Saltear las pausas (solo pruebas).
@export var quick := false

var ending_played := false


func _ready() -> void:
	chip.vanish()
	glitch.vanish()
	var state := _state()
	props.alert = not state.has_flag(&"cap1_hermanos_vencidos")
	props.genesis = false
	if profesor:
		profesor.talked.connect(_on_profesor_talked)
	_on_enter.call_deferred()


func _on_enter() -> void:
	if _state().get_current_step(QUEST) != &"revisar_servidor":
		return
	for k in 2:
		var actor: SiblingActor = [chip, glitch][k]
		actor.position = monitor_point + Vector2(-20 + k * 40, 52)
		actor.appear()
	await StoryHelper.say(self, server_dialogue)
	for actor in [chip, glitch]:
		actor.run_to(monitor_point, 160.0)
	await get_tree().create_timer(0.5 if quick else 0.8, false, true).timeout
	chip.vanish()
	glitch.vanish()
	_state().complete_step(QUEST, &"revisar_servidor")


func _on_profesor_talked(_first_time: bool) -> void:
	if ending_played or _state().get_current_step(QUEST) != &"hablar_profesor":
		return
	ending_played = true
	await _genesis_ending()


## Kai se va. Escena aparte: el profesor, solo, ve aparecer GENESIS_ARCHIVE; «FIN DEL CAPÍTULO 1»; y Kai
## aparece en la entrada del colegio.
func _genesis_ending() -> void:
	var room := get_parent() as Room
	var player := room.player
	var camera := room.camera
	var scenes := get_node("/root/SceneManager")
	player.controls_locked = true
	camera.target = null
	var tween := player.create_tween()
	tween.tween_property(player, "global_position:x", leave_point.x, 0.4 if quick else 1.6)
	tween.parallel().tween_property(player, "modulate:a", 0.0, 0.4 if quick else 1.6)
	await tween.finished
	# Corte a negro: «Mientras tanto...» y el profesor solo frente al monitor.
	var caption := [null]
	var objective := room.get_node_or_null("CombatHUD/Objective") as CanvasItem
	await scenes.transition(func() -> void:
		player.visible = false
		if objective:
			objective.modulate.a = 0.0  # Es una escena aparte: sin el objetivo de Kai.
		camera.global_position = Vector2((profesor.global_position.x + monitor_point.x) / 2.0, monitor_point.y + 8.0)
		caption[0] = _show_caption(room, "Mientras tanto, en el cuarto técnico..."))
	await _wait(2.4)
	if is_instance_valid(caption[0]):
		caption[0].queue_free()
	props.genesis = true
	Sfx.play(&"popup_open", 0.6)
	# La cámara se acerca despacio al monitor: el archivo es lo importante de la escena.
	var zoom_in := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zoom_in.tween_property(camera, "zoom", camera.zoom * 2.2, 2.4 * (0.15 if quick else 1.0))
	zoom_in.tween_property(camera, "global_position", monitor_point + Vector2(-30, 44), 2.4 * (0.15 if quick else 1.0))
	await _wait(2.6)
	if genesis_dialogue:
		await StoryHelper.say(self, genesis_dialogue)
	_state().set_flag(ENDING_FLAG)
	# «FIN DEL CAPÍTULO 1» sobre la imagen del profesor y el archivo.
	_state().complete_step(QUEST, &"hablar_profesor")
	await _wait(0.3)
	var card := room.get_node_or_null("CombatHUD/TitleCard")
	while card and card.is_showing() and not quick:
		await get_tree().process_frame
	# Kai aparece en otro lugar (la entrada del colegio): no vuelve al cuarto.
	scenes.go_to_room(after_scene, after_entry, after_room)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * (0.15 if quick else 1.0), false, true).timeout


func _show_caption(room: Room, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 6)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_top = -90.0
	label.offset_bottom = -60.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room.get_node("CombatHUD").add_child(label)
	return label


func _state() -> Node:
	return get_node("/root/GameState")
