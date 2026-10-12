class_name ChoiceOption
extends Resource
## Una opción de una pregunta (ChoiceQuestion): el texto, si es la correcta y la explicación que se
## muestra al elegirla (por qué sí o por qué no).

@export var text := ""
## Línea pequeña bajo la opción (p. ej. un ejemplo).
@export var detail := ""
@export var correct := false
@export_multiline var feedback := ""
