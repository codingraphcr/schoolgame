class_name NpcBark
extends Area2D
## Hace que un NPC de fondo diga algo (un globo) cuando Kai pasa cerca: le da vida al colegio. Una vez
## por visita a la sala. Si tiene misión y paso, solo durante ese paso.

@export var npc: Node2D
@export var lines: PackedStringArray = []
@export var quest_id: StringName = &""
@export var step_id: StringName = &""
@export var radius := 60.0

var said := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	shape.position = Vector2(0, -16)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if said or not body is Player or npc == null or lines.is_empty():
		return
	if quest_id != &"" and get_node("/root/GameState").get_current_step(quest_id) != step_id:
		return
	said = true
	SpeechBark.say(npc, lines[randi() % lines.size()], Vector2(0, -44), 2.2)
