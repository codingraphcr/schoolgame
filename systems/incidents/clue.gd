class_name Clue
extends Resource
## Evidencia que el jugador descubre al investigar un incidente
## (en una computadora, hablando con un NPC, revisando un registro...).

@export var id: StringName
@export var title := ""
## Explicación que se muestra al encontrarla y en la terminal de seguridad.
@export_multiline var description := ""
