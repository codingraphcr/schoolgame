@tool
extends Node2D
## Detalles del Bosque de Fibra que se dibujan sobre el fondo:
## - "fragmento": un Fragmento de Datos que solo se ve con la Visión (y desaparece al recogerlo: collected_flag).
## - "troncal": la troncal de fibra hacia el Distrito Caché, cortada (un cable grueso roto y, del otro lado,
##   luces lejanas de una ciudad).
## - "salida": el nodo de salida hacia el mundo físico (un anillo de luz).

@export_enum("fragmento", "troncal", "salida") var kind := "fragmento"
@export var collected_flag: StringName = &""

var _clock := 0.0


func _ready() -> void:
	if kind == "fragmento" and not Engine.is_editor_hint():
		add_to_group(&"digital_only")
		visible = get_node("/root/DigitalVision").is_active()


func _process(delta: float) -> void:
	_clock += delta
	if kind == "fragmento" and not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(collected_flag):
		modulate.a = 0.0
	queue_redraw()


func _draw() -> void:
	match kind:
		"fragmento":
			KeepsakeArt.draw_art(self, &"fragmento", Rect2(-10, -26 + sin(_clock * 2.0) * 2.0, 20, 20), _clock)
		"troncal":
			# Cable grueso que llega desde la izquierda y se corta; chispas; luces de ciudad al fondo.
			draw_line(Vector2(-90, -40), Vector2(-14, -40), Color("1e3048"), 10.0)
			draw_line(Vector2(-90, -40), Vector2(-14, -40), Color(0.24, 0.95, 1.0, 0.35), 3.0)
			draw_line(Vector2(14, -38), Vector2(60, -36), Color("1e3048"), 10.0)
			if fmod(_clock, 1.4) < 0.25:
				draw_line(Vector2(-14, -44), Vector2(-4, -34), Color("ff4a6a"), 2.0)
				draw_line(Vector2(14, -34), Vector2(6, -46), Color("ff4a6a"), 2.0)
			for k in 7:
				draw_rect(Rect2(Vector2(20 + k * 7, -110 + (k % 3) * 10), Vector2(4, 30 - (k % 3) * 8)), Color(1.0, 0.82, 0.3, 0.25))
		"salida":
			var pulse := 0.5 + 0.5 * sin(_clock * 3.0)
			draw_arc(Vector2(0, -30), 18.0, 0, TAU, 32, Color(0.24, 0.95, 1.0, 0.6 + pulse * 0.4), 2.5)
			draw_arc(Vector2(0, -30), 24.0 + pulse * 3.0, 0, TAU, 32, Color(0.24, 0.95, 1.0, 0.2), 2.0)
