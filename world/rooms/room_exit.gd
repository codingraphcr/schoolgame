class_name RoomExit
extends Area2D
## Salida hacia otra sala (en los bordes, como en Hollow Knight). Al entrar el jugador hay un
## fundido y aparece en la RoomEntry de la otra sala cuyo id es target_entry.

@export_file("*.tscn") var target_scene := ""
@export var target_entry: StringName = &""

var _used := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _used or not body is Player or target_scene.is_empty():
		return
	_used = true
	(body as Player).controls_locked = true
	get_node("/root/SceneManager").go_to_room(target_scene, target_entry)
