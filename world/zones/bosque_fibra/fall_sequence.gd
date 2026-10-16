class_name FallSequence
extends Node
## La caída accidental (Capítulo 3, «Contagio digital», en la conexión del equipo 7), hija de la sala:
## 1. Al acercarse al final (warning_x), el Grimorio avisa que la plataforma no es estable; Kai, confiado, decide saltar.
## 2. Al pisar la plataforma (platform), tiembla y se desintegra; Kai cae por el conducto (FallOverlay, con sus
##    comentarios), sin daño ni pérdidas, y aterriza en una región que no conoce (landing_scene / landing_entry).
## Solo durante el paso step_id de quest_id; una sola vez (después el paso ya cambió).

@export var platform: DataPlatform
@export var warning_x := 860.0
@export var warning_lines: PackedStringArray = ["ADVERTENCIA DE INTEGRIDAD", "Plataforma inestable · integridad: 12 %", "No se recomienda pisarla"]
@export var confident_dialogue: Dialogue
@export var fall_lines: PackedStringArray = []
@export_file("*.tscn") var landing_scene := ""
@export var landing_entry: StringName = &"caida"
@export var quest_id: StringName = &"contagio_digital"
@export var step_id: StringName = &"investigar_conexion"
@export var quick := false

var _warned := false
var falling := false


func _physics_process(_delta: float) -> void:
	if falling or _state().get_current_step(quest_id) != step_id:
		return
	var player := (get_parent() as Room).player
	if player == null:
		return
	if not _warned and player.global_position.x >= warning_x:
		_warned = true
		_warn()
	elif _on_platform(player):
		fall()


func _on_platform(player: Player) -> bool:
	if platform == null or not player.is_on_floor():
		return false
	var top := platform.global_position
	return player.global_position.x >= top.x and player.global_position.x <= top.x + platform.width and absf(player.global_position.y - top.y) < 6.0


func _warn() -> void:
	GrimorioAlert.show_lines(self, warning_lines, 1.0 if quick else 3.0)
	await StoryHelper.say(self, confident_dialogue)


## La plataforma se desintegra y Kai cae (escena: no hay daño).
func fall() -> void:
	if falling:
		return
	falling = true
	var player := (get_parent() as Room).player
	player.controls_locked = true
	player.velocity = Vector2.ZERO
	Sfx.play(&"monitor_static")
	var shake := create_tween()
	for k in 6:
		shake.tween_property(platform, "position:x", platform.position.x + (3.0 if k % 2 == 0 else -3.0), 0.05)
	await shake.finished
	platform.force_close(9999.0)  # No vuelve: el camino de regreso queda roto.
	player.set_physics_process(false)
	var drop := create_tween()
	drop.tween_property(player, "global_position:y", player.global_position.y + 60.0, 0.35)
	await drop.finished
	await FallOverlay.play(self, fall_lines, 0.6 if quick else 5.5).finished
	player.set_physics_process(true)
	get_node("/root/SceneManager").go_to_room(landing_scene, landing_entry)


func _state() -> Node:
	return get_node("/root/GameState")
