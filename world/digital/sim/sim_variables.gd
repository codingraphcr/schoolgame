class_name SimVariables
extends Node
## Las variables de una sala del simulador (Capítulo 2): nombre → valor. Los nodos de variable las
## cambian (VariableNode) y las puertas, plataformas y puentes las leen (LogicDoor, LogicPlatform,
## LoopBridge). Avisa cada cambio con changed.

signal changed(variable: StringName, value: Variant)

## Valores al entrar a la sala.
@export var initial: Dictionary[StringName, Variant] = {}

var values: Dictionary[StringName, Variant] = {}


func _ready() -> void:
	values = initial.duplicate()


func get_value(variable: StringName) -> Variant:
	return values.get(variable)


func set_value(variable: StringName, value: Variant) -> void:
	if values.get(variable) == value:
		return
	values[variable] = value
	changed.emit(variable, value)


## Cómo se escribe un valor en el pseudocódigo del juego (verdadero/falso en español).
static func format(value: Variant) -> String:
	if value is bool:
		return "verdadero" if value else "falso"
	if value is String or value is StringName:
		return String(value)
	return str(value)


## Evalúa una condición: lista de cláusulas [variable, operador, valor] unidas con «y» (all = true) o
## «o». Operadores: ==, !=, >=, <=, >, <.
static func evaluate(clauses: Array, values_now: Dictionary, all := true) -> bool:
	if clauses.is_empty():
		return true
	for clause in clauses:
		var ok := _compare(values_now.get(clause[0]), String(clause[1]), clause[2])
		if all and not ok:
			return false
		if not all and ok:
			return true
	return all


## La condición escrita como pseudocódigo: «si llave == verdadero y energia >= 3».
static func describe(clauses: Array, all := true) -> String:
	var parts: PackedStringArray = []
	for clause in clauses:
		parts.append("%s %s %s" % [clause[0], clause[1], format(clause[2])])
	return "si " + (" y " if all else " o ").join(parts)


static func _compare(left: Variant, op: String, right: Variant) -> bool:
	if left == null:
		return false
	match op:
		"==":
			return left == right
		"!=":
			return left != right
		">=":
			return left >= right
		"<=":
			return left <= right
		">":
			return left > right
		"<":
			return left < right
	return false
