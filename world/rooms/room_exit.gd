class_name RoomExit
extends Area2D
## Salida hacia otra sala (en los bordes, como en Hollow Knight). Al entrar el jugador hay un
## fundido y aparece en la RoomEntry de la otra sala.
##
## Si tiene door_id y la sala está en el mapa (World), el mapa dice a dónde lleva esa puerta.
## Si no, usa target_scene y target_entry (como respaldo, y para salas fuera del mapa).
## Puede estar cerrada hasta que una misión llegue a un paso (requires_quest / requires_step):
## mientras tanto la pared de la sala frena a Kai y se avisa locked_message.

## Puerta de la ficha de la sala (DoorSpec.id) que representa esta salida.
@export var door_id: StringName = &""
@export_file("*.tscn") var target_scene := ""
@export var target_entry: StringName = &""
@export var requires_quest: StringName = &""
## Paso de requires_quest desde el que se abre (vacío = basta con que la misión haya empezado).
@export var requires_step: StringName = &""
@export var locked_message := ""

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


## Si se puede pasar (no pide misión, o la misión ya llegó a ese paso).
func is_open() -> bool:
	if requires_quest == &"":
		return true
	return get_node("/root/GameState").has_reached_step(requires_quest, requires_step)


func _on_body_entered(body: Node) -> void:
	if _used or not body is Player:
		return
	if not is_open():
		if not locked_message.is_empty():
			get_tree().call_group(&"toast", &"show_message", locked_message, 2.5)
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
