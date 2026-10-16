class_name NpcConversation
extends Resource
## Lo que dice un NPC mientras una misión está en un paso concreto (o, con step_id vacío, mientras la misión
## está en curso, en cualquier paso: sirve para lo que dice en todo un capítulo). Si completes_step es true,
## al terminar de hablar se completa ese paso (y la misión avanza).

@export var quest_id: StringName = &""
@export var step_id: StringName = &""
@export var dialogue: Dialogue
@export var completes_step := false
## Solo vale si la partida tiene esta marca (vacío = siempre). Sirve para que un NPC recuerde algo (p. ej. una elección).
@export var requires_flag: StringName = &""
