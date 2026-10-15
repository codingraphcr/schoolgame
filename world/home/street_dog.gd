@tool
extends Node2D
## El perro del barrio, echado en la acera (dibujo provisional): mueve la cola, de vez en cuando levanta
## la cabeza y, si Kai lo acaricia (un Examinable hijo), se alegra un rato (wag más rápido). Detalle
## de ambiente: no da nada.

const FUR := Color("c8864a")
const FUR_DARK := Color("8a5a30")

@export var happy_time := 2.5

var _clock := 0.0
var _happy := 0.0


func _ready() -> void:
	for child in get_children():
		if child is Examinable:
			child.examined.connect(func(_times: int) -> void: pet())


func pet() -> void:
	_happy = happy_time


func _process(delta: float) -> void:
	_clock += delta
	_happy = maxf(_happy - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var wag := sin(_clock * (18.0 if _happy > 0.0 else 5.0)) * (5.0 if _happy > 0.0 else 3.0)
	var head_up := 4.0 if _happy > 0.0 or fmod(_clock, 7.0) < 1.5 else 0.0
	draw_line(Vector2(-14, -6), Vector2(-24, -10 + wag), FUR_DARK, 3.0)  # Cola
	draw_rect(Rect2(-16, -10, 26, 10), FUR)  # Cuerpo echado
	draw_rect(Rect2(-12, -2, 22, 2), FUR_DARK)
	draw_circle(Vector2(12, -9 - head_up), 6.0, FUR)  # Cabeza
	draw_rect(Rect2(14, -10 - head_up, 7, 5), FUR)  # Hocico
	draw_circle(Vector2(20, -9 - head_up), 1.2, Color("1a1424"))
	draw_circle(Vector2(13, -11 - head_up), 1.0, Color("1a1424"))
	draw_rect(Rect2(7, -15 - head_up, 4, 6), FUR_DARK)  # Oreja
	if _happy > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(4, -22 - head_up), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ff6a8a"))
