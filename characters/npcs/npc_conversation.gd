class_name NpcConversation
extends Resource
## Lo que dice un NPC mientras una misión está en un paso concreto. Si completes_step es true,
## al terminar de hablar se completa ese paso (y la misión avanza).

@export var quest_id: StringName = &""
@export var step_id: StringName = &""
@export var dialogue: Dialogue
@export var completes_step := false
