class_name QuestStarter
extends Area2D
## Empieza una misión (p. ej. una secundaria) cuando Kai entra en la zona y se cumple requirement (capítulo,
## marcas, habilidades: WorldRequirement). Puede mostrar un diálogo antes. Solo una vez: si la misión ya
## empezó o terminó, no hace nada. Necesita una CollisionShape2D hija.

signal started(quest_id: StringName)

@export var quest_id: StringName = &""
@export var requirement: WorldRequirement
@export var dialogue: Dialogue

var _busy := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	body_entered.connect(_on_body_entered)


func can_start() -> bool:
	var state := get_node("/root/GameState")
	return not state.has_reached_step(quest_id) and (requirement == null or requirement.is_met(state))


func _on_body_entered(body: Node) -> void:
	if _busy or not body is Player or not can_start():
		return
	_busy = true
	if dialogue:
		await StoryHelper.say(self, dialogue)
	get_node("/root/GameState").start_quest(quest_id)
	started.emit(quest_id)
	_busy = false
