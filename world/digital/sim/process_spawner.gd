class_name ProcessSpawner
extends Node2D
## Generador de procesos repetidos (Capítulo 2, nivel 4): «mientras verdadero: crear_proceso()». Cada
## interval segundos (tiempo de las amenazas: el Dominio lo frena) crea un RepeatedProcess, hasta
## max_alive a la vez. stop() corta el ciclo: deja de crear y deshace los que hay.

signal stopped

@export var interval := 2.2
@export var max_alive := 4
@export var running := true

var spawned: Array[RepeatedProcess] = []
var _timer := 0.0
var _clock := 0.0


func _physics_process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if not running:
		return
	_timer += CombatClock.scaled(delta)
	spawned = spawned.filter(func(p: RepeatedProcess) -> bool: return is_instance_valid(p) and not p.is_dead)
	if _timer >= interval and spawned.size() < max_alive:
		_timer = 0.0
		spawn()


func spawn() -> RepeatedProcess:
	var process := RepeatedProcess.new()
	get_parent().add_child(process)
	process.global_position = global_position + Vector2(0, 0)
	spawned.append(process)
	return process


func stop() -> void:
	if not running:
		return
	running = false
	for process in spawned:
		if is_instance_valid(process):
			process.dissolve()
	spawned.clear()
	stopped.emit()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var color := Color("ff7a5c") if running else Color("5dff9a")
	var pulse := 0.5 + 0.5 * sin(_clock * 6.0) if running else 1.0
	draw_arc(Vector2(0, -20), 14.0, _clock * 3.0, _clock * 3.0 + TAU * 0.8, 24, Color(color, 0.4 + 0.5 * pulse), 2.0)
	draw_string(font, Vector2(-40, -42), "mientras verdadero:" if running else "ciclo detenido", HORIZONTAL_ALIGNMENT_CENTER, 80, 8, color)
	if running:
		draw_string(font, Vector2(-40, -32), "crear_proceso()", HORIZONTAL_ALIGNMENT_CENTER, 80, 8, color)
