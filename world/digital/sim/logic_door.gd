class_name LogicDoor
extends ArenaBarrier
## Puerta del simulador (Capítulo 2): se abre cuando se cumple su condición sobre las variables de la
## sala (SimVariables). Muestra la condición escrita como pseudocódigo arriba («si llave == verdadero y
## energia >= 3») en rojo mientras no se cumple y en verde cuando sí.

signal opened

@export var variables: SimVariables
## Cláusulas [variable, operador, valor] (ver SimVariables.evaluate).
@export var clauses: Array = []
## true: todas («y»); false: alguna («o»).
@export var all := true

var is_open := false
var _label: Label


func _ready() -> void:
	active = true
	super()
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(200, 12)
	_label.position = Vector2(-100, -height - 16)
	add_child(_label)
	if variables:
		variables.changed.connect(func(_name: StringName, _value: Variant) -> void: refresh())
	refresh.call_deferred()


func condition_met() -> bool:
	return variables != null and SimVariables.evaluate(clauses, variables.values, all)


func refresh() -> void:
	var met := condition_met()
	_label.text = SimVariables.describe(clauses, all) + (" ✔" if met else "")
	_label.add_theme_color_override("font_color", Color("5dff9a") if met else Color("ff6b8a"))
	if met and not is_open:
		is_open = true
		active = false
		Sfx.play(&"terminal_ok", 1.0)
		opened.emit()
	elif not met and is_open:
		is_open = false
		active = true
