class_name EscapeBridge
extends Node2D
## El último tramo del escape de la Estación Lázaro (Capítulo 3), hijo de la sala: un puente que se está deshaciendo.
## Aegis se queda sosteniéndolo (su cuerpo junto al mecanismo, platforms estabilizadas en azul) mientras Kai cruza.
## Cuando Kai llega al otro lado (far_x): «¡Aegis, la tuya también importa!» (leave_dialogue); Aegis suelta el
## mecanismo y vuela con Kai; el puente cae detrás. Aegis empieza a entender que también puede cuidarse a sí mismo.
## Pasa una sola vez (HELD_FLAG); después el puente ya cayó y hay otra ruta.

const HELD_FLAG := &"lazaro_puente_soltado"
const BLUE := Color(0.55, 0.85, 1.35)

@export var platforms: Array[NodePath] = []
@export var holder: AegisBody
@export var hold_x := 300.0
@export var far_x := 900.0
@export var hold_dialogue: Dialogue
@export var leave_dialogue: Dialogue
@export var quick := false

var holding := false
var done := false


func _ready() -> void:
	done = _state().has_flag(HELD_FLAG)
	if holder:
		holder.visible = false
	if done:
		for path in platforms:
			var platform := get_node_or_null(path) as DataPlatform
			if platform:
				platform.force_close(99999.0)


func _physics_process(_delta: float) -> void:
	if done:
		return
	var player := StoryHelper.room_player(self)
	if player == null:
		return
	if not holding and player.global_position.x >= hold_x:
		_hold()
	elif holding and player.global_position.x >= far_x and not player.controls_locked:
		_leave()


func _hold() -> void:
	holding = true
	var companion := _companion()
	if companion:
		companion.visible = false
	if holder:
		holder.visible = true
		holder.mood = AegisBody.Mood.FLOTANDO
	for path in platforms:
		var platform := get_node_or_null(path) as DataPlatform
		if platform:
			platform.stabilized = true
			platform.modulate = BLUE
	await StoryHelper.say(self, hold_dialogue)


func _leave() -> void:
	done = true
	_state().set_flag(HELD_FLAG)
	await StoryHelper.say(self, leave_dialogue)
	for path in platforms:
		var platform := get_node_or_null(path) as DataPlatform
		if platform:
			platform.stabilized = false
			platform.modulate = Color.WHITE
			platform.force_close(99999.0)
	if holder:
		var player := StoryHelper.room_player(self)
		var fly := create_tween()
		fly.tween_property(holder, "global_position", player.global_position + Vector2(-22, -48), 0.3 if quick else 0.8)
		await fly.finished
		holder.visible = false
	var companion := _companion()
	if companion:
		companion.visible = true


func _companion() -> AegisCompanion:
	var room := get_parent()
	for node in room.find_children("*", "AegisCompanion", true, false):
		return node as AegisCompanion
	return null


func _state() -> Node:
	return get_node("/root/GameState")
