class_name LoopBridge
extends Node2D
## Puente de un ciclo (Capítulo 2): «repetir n veces: poner bloque». Lee n de una variable de la sala
## (SimVariables) y arma n bloques de block_width desde su posición hacia la derecha. Solo con el n justo
## cruza el hueco: con menos queda corto; con más, el último bloque chocaría con la pared y el ciclo
## falla (no se arma nada: «ERROR»). completed avisa la primera vez que queda bien.

signal completed

@export var variables: SimVariables
@export var variable: StringName = &"n"
@export var needed := 4
@export var block_width := 32.0

var built: Array[DataPlatform] = []
var is_complete := false
var _message := ""


func _ready() -> void:
	if variables:
		variables.changed.connect(func(_name: StringName, _value: Variant) -> void: rebuild())
	rebuild.call_deferred()


func count() -> int:
	return int(variables.get_value(variable)) if variables and variables.get_value(variable) != null else 0


func rebuild() -> void:
	for block in built:
		if is_instance_valid(block):
			block.queue_free()
	built.clear()
	var n := count()
	if n > needed:
		_message = "ERROR: el bloque %d choca con la pared" % (needed + 1)
		Sfx.play(&"error", 1.0, -6.0)
	else:
		for i in n:
			var block := DataPlatform.new()
			block.width = block_width - 2.0
			block.position = Vector2(i * block_width, 0)
			add_child(block)
			built.append(block)
		_message = "✔ el puente llega" if n == needed else "faltan bloques (%d de %d)" % [n, needed]
	if n == needed and not is_complete:
		is_complete = true
		Sfx.play(&"terminal_ok", 1.1)
		completed.emit()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var ok := count() == needed
	draw_string(font, Vector2(0, -44), "repetir %s veces:" % variable, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("3ef2ff"))
	draw_string(font, Vector2(12, -33), "poner_bloque()", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("3ef2ff"))
	draw_string(font, Vector2(0, -20), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("5dff9a") if ok else Color("ff6b8a"))
	# Dónde iría cada bloque (punteado).
	for i in needed:
		var x := i * block_width
		draw_rect(Rect2(Vector2(x + 1, 0), Vector2(block_width - 4, 8)), Color(0.5, 0.6, 0.9, 0.25), false, 1.0)
