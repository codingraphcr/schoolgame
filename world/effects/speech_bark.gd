class_name SpeechBark
extends Node2D
## Globo de texto que flota sobre un personaje unos segundos, sin pausar el juego ni quitarle el control
## a Kai (las frases de Bucle durante el combate). Sigue a su dueño y se desvanece solo.
## Uso: SpeechBark.say(dueño, "Otra vez.", Vector2(0, -40))

const BUBBLE := Color("fff4dc")
const TEXT := Color("2a1a08")
const EDGE := Color("ffb347")

var text := ""
var duration := 2.6
var offset := Vector2(0, -40)
var target: Node2D

var _time := 0.0


## Muestra la frase sobre owner_node (reemplaza la anterior si había una).
static func say(owner_node: Node2D, line: String, at := Vector2(0, -40), seconds := 2.6) -> SpeechBark:
	for child in owner_node.get_parent().get_children():
		if child is SpeechBark and (child as SpeechBark).target == owner_node:
			child.queue_free()
	var bark := SpeechBark.new()
	bark.text = line
	bark.offset = at
	bark.duration = seconds
	bark.target = owner_node
	bark.z_index = 30
	owner_node.get_parent().add_child(bark)
	bark.global_position = owner_node.global_position + at
	return bark


func _process(delta: float) -> void:
	_time += delta
	if is_instance_valid(target):
		global_position = target.global_position + offset
	modulate.a = clampf(minf(_time / 0.15, (duration - _time) / 0.4), 0.0, 1.0)
	if _time >= duration:
		queue_free()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	var rect := Rect2(Vector2(-size.x / 2.0 - 6.0, -size.y - 8.0), Vector2(size.x + 12.0, size.y + 8.0))
	draw_rect(rect, BUBBLE)
	draw_rect(rect, EDGE, false, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, rect.end.y), Vector2(4, rect.end.y), Vector2(0, rect.end.y + 5)]), BUBBLE)
	draw_string(font, Vector2(rect.position.x + 6.0, rect.end.y - 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
