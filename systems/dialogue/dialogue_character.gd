class_name DialogueCharacter
extends Resource
## Personaje que habla en los diálogos: nombre, título y retrato (estilo Hades).
## Un .tres por personaje en data/characters/; la caja de diálogo los carga todos.
## En los diálogos se escribe "Nombre: texto" o "Nombre [expresion]: texto".

enum Side { LEFT, RIGHT }

## Nombre tal como aparece en los diálogos y en la placa (p. ej. "Prof. Alvarado").
@export var display_name := ""
## Otros nombres que también lo identifican en los diálogos (p. ej. "Profesor").
@export var aliases: PackedStringArray = []
## Texto pequeño bajo el nombre (p. ej. "Mentor").
@export var title := ""
@export var portrait: Texture2D
## Retratos alternativos por expresión: { "serio": Texture2D, ... }.
@export var expressions: Dictionary[String, Texture2D] = {}
## Lado de la pantalla donde aparece su retrato. Kai a la izquierda, el resto a la derecha.
@export var side := Side.LEFT
## Si el retrato mira hacia el lado contrario al que debería, se voltea.
@export var flip_portrait := false
## Color del nombre y del borde de la placa.
@export var accent := Color(0.243, 0.949, 1.0)
## Color del texto de sus líneas (transparente = el color normal de la caja).
@export var text_color := Color(0, 0, 0, 0)
## Si su texto tiembla como una señal con interferencia (para presencias misteriosas).
@export var glitch := false


func matches(speaker: String) -> bool:
	return speaker == display_name or speaker in aliases


func portrait_for(expression: String) -> Texture2D:
	if not expression.is_empty() and expressions.has(expression):
		return expressions[expression]
	return portrait
