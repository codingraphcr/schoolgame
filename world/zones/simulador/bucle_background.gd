@tool
extends Node2D
## Fondo del simulador donde está Bucle (Capítulo 2), dibujado por código hasta que Ariel lo dibuje: una
## grilla de datos y columnas de código que caen. Con cada etapa de Bucle (stage 1 a 7) el código se
## acumula: más columnas, más rápido, y el color pasa de cálido a rojo. Desde la etapa 6 aparecen
## franjas de interferencia (suaves con «reducir glitch»). Nunca tapa las plataformas ni los ataques:
## todo es tenue y queda detrás.

const GRID := Color(1.0, 0.75, 0.4, 0.07)
const BASE := Color("120a14")
const WARM := Color("ffb347")
const RED := Color("ff4a6a")
const WORDS: PackedStringArray = ["repetir()", "mientras", "i = i + 1", "otra vez", "tarea()", "loop", "¿fin?"]

@export var area := Rect2(0, 0, 640, 360)
@export var stage := 1:
	set(value):
		stage = clampi(value, 1, 7)
		queue_redraw()

var _clock := 0.0


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(area, BASE)
	var x := area.position.x
	while x < area.end.x:
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), GRID, 1.0)
		x += 32.0
	var y := area.position.y
	while y < area.end.y:
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), GRID, 1.0)
		y += 32.0
	var t := (stage - 1) / 6.0
	var color := WARM.lerp(RED, t)
	var font := ThemeDB.fallback_font
	var columns := 4 + stage * 3
	for i in columns:
		var column_x := area.position.x + fmod(i * 97.0, area.size.x)
		var speed := 18.0 + stage * 6.0 + (i % 3) * 7.0
		var top := fmod(_clock * speed + i * 53.0, area.size.y + 60.0) - 40.0
		for k in 3:
			var word := WORDS[(i + k) % WORDS.size()]
			draw_string(font, Vector2(column_x, area.position.y + top - k * 12.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
				Color(color, 0.16 - k * 0.04))
	if stage >= 6 and not Engine.is_editor_hint():
		var glitch := GameSettings.glitch_factor()
		for i in int((stage - 5) * 3 * glitch):
			var noise := fmod(sin(_clock * 3.1 + i * 7.7) * 4375.85, 1.0)
			var band := area.position.y + absf(noise) * area.size.y
			draw_rect(Rect2(area.position.x, band, area.size.x, 2.0), Color(RED, 0.08 * glitch))
