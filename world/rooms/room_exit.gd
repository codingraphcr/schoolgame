class_name RoomExit
extends Area2D
## Salida hacia otra sala (en los bordes, como en Hollow Knight). Al entrar el jugador hay un
## fundido y aparece en la RoomEntry de la otra sala.
##
## Si tiene door_id y la sala está en el mapa (World), el mapa dice a dónde lleva esa puerta.
## Si no, usa target_scene y target_entry (como respaldo, y para salas fuera del mapa).

## Puerta de la ficha de la sala (DoorSpec.id) que representa esta salida.
@export var door_id: StringName = &""
@export_file("*.tscn") var target_scene := ""
@export var target_entry: StringName = &""

var _used := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	body_entered.connect(_on_body_entered)


## A dónde lleva: { "scene", "entry", "room" } (room vacío si no viene del mapa).
func resolve() -> Dictionary:
	var room := _room()
	var world := get_node_or_null("/root/World")
	if world and room and room.room_id != &"" and door_id != &"":
		var target: Dictionary = world.destination(room.room_id, door_id)
		if not target.is_empty():
			return target
	return { "scene": target_scene, "entry": target_entry, "room": &"" }


func _on_body_entered(body: Node) -> void:
	if _used or not body is Player:
		return
	var target := resolve()
	if String(target["scene"]).is_empty():
		return
	_used = true
	(body as Player).controls_locked = true
	get_node("/root/SceneManager").go_to_room(target["scene"], target["entry"], target["room"])


func _room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room
