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
	return destination_of(self, door_id, target_scene, target_entry)


## A dónde lleva la puerta door_id de la sala donde está node: lo que diga el mapa (World) o, si no
## lo sabe, el respaldo. También lo usan las escaleras (Stairway).
static func destination_of(node: Node, door: StringName, fallback_scene: String, fallback_entry: StringName) -> Dictionary:
	var room := _room_of(node)
	var world := node.get_node_or_null("/root/World")
	if world and room and room.room_id != &"" and door != &"":
		var target: Dictionary = world.destination(room.room_id, door)
		if not target.is_empty():
			return target
	return { "scene": fallback_scene, "entry": fallback_entry, "room": &"" }


## Lleva a Kai por esa puerta. false si no lleva a ningún lado o si la sala de destino todavía está
## cerrada (es de un capítulo que no empezó: avisa por qué).
static func travel(node: Node, player: Player, door: StringName, fallback_scene: String, fallback_entry: StringName) -> bool:
	var target := destination_of(node, door, fallback_scene, fallback_entry)
	if String(target["scene"]).is_empty():
		return false
	var world := node.get_node_or_null("/root/World")
	if world and target["room"] != &"":
		var reason: String = world.lock_reason(target["room"])
		if not reason.is_empty():
			node.get_tree().call_group(&"toast", &"show_message", reason, 2.5)
			return false
	player.controls_locked = true
	node.get_node("/root/SceneManager").go_to_room(target["scene"], target["entry"], target["room"])
	return true


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
	_used = travel(self, body as Player, door_id, target_scene, target_entry)


static func _room_of(node: Node) -> Room:
	var parent := node.get_parent()
	while parent and not parent is Room:
		parent = parent.get_parent()
	return parent as Room
