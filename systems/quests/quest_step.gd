class_name QuestStep
extends Resource
## Un paso de una misión: lo que el jugador debe hacer ahora (se muestra como OBJETIVO).

@export var id: StringName = &""
@export_multiline var objective := ""
## Sala del mapa (room_id de World) a la que hay que ir para este paso: el mapa del Grimorio la marca.
## Vacío = no se marca ninguna.
@export var room_id: StringName = &""
