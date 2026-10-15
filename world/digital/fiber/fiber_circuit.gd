class_name FiberCircuit
extends Node2D
## Un tramo de fibra cortado en el Bosque de Fibra (misión «Sin señal en el barrio»): la señal sale de un
## origen, pasa por empalmes (FiberJunction) y tiene que llegar al destino. Cada empalme tiene que apuntar
## al siguiente punto del camino: si uno apunta a otro lado, ese tramo queda a oscuras y la señal no llega
## (un enlace roto corta la comunicación). Se puede tocar solo durante quest_id / step_id; al reconectar
## todo, la luz corre por el cable, se completa el paso y queda conectado para siempre (la misión avanzó).
## Los puntos están en coordenadas locales: source → junctions (en orden) → sink.

signal solved

const DARK := Color("2a3a5a")
const LIGHT := Color("fff0a0")

@export var junctions: Array[FiberJunction] = []
@export var source := Vector2.ZERO
@export var sink := Vector2(200, 0)
@export var quest_id: StringName = &"senal_del_barrio"
@export var step_id: StringName = &"reconectar"

var is_solved := false
var _clock := 0.0


func _ready() -> void:
	var points := path()
	for i in junctions.size():
		var direction := (points[i + 2] - points[i + 1]).normalized()
		junctions[i].correct = _direction_index(direction)
		junctions[i].turned.connect(func(_junction: FiberJunction) -> void: _check())
	if _already_done():
		is_solved = true
		for junction in junctions:
			junction.orientation = junction.correct
	_refresh()


func _process(delta: float) -> void:
	_clock += delta
	var active: bool = not is_solved and get_node("/root/GameState").get_current_step(quest_id) == step_id
	for junction in junctions:
		junction.interactable.enabled = active
	queue_redraw()


## El camino de la señal: origen, empalmes y destino (locales).
func path() -> Array[Vector2]:
	var points: Array[Vector2] = [source]
	for junction in junctions:
		points.append(junction.position)
	points.append(sink)
	return points


## Cuántos tramos llevan señal (desde el origen, hasta el primer empalme mal puesto).
func lit_segments() -> int:
	var count := 1
	for junction in junctions:
		if not junction.is_correct():
			return count
		count += 1
	return count


func _check() -> void:
	_refresh()
	if is_solved or lit_segments() <= junctions.size():
		return
	is_solved = true
	Sfx.play(&"fanfare", 1.2)
	var state := get_node("/root/GameState")
	if state.get_current_step(quest_id) == step_id:
		state.complete_step(quest_id, step_id)
	solved.emit()


func _refresh() -> void:
	var lit := lit_segments()
	for i in junctions.size():
		junctions[i].lit = is_solved or i < lit
		junctions[i].queue_redraw()


func _already_done() -> bool:
	var state := get_node("/root/GameState")
	return state.is_quest_completed(quest_id) or (state.has_reached_step(quest_id, step_id) and state.get_current_step(quest_id) != step_id)


static func _direction_index(direction: Vector2) -> int:
	var best := 0
	for i in FiberJunction.DIRECTIONS.size():
		if FiberJunction.DIRECTIONS[i].dot(direction) > FiberJunction.DIRECTIONS[best].dot(direction):
			best = i
	return best


func _draw() -> void:
	var points := path()
	var lit := junctions.size() + 1 if is_solved else lit_segments()
	for i in points.size() - 1:
		var on := i < lit
		draw_line(points[i], points[i + 1], LIGHT if on else DARK, 3.0)
		if on:
			# Pulsos de luz que corren por el tramo.
			var t := fmod(_clock * 0.8 + i * 0.3, 1.0)
			draw_circle(points[i].lerp(points[i + 1], t), 3.0, Color(1, 1, 1, 0.8))
	draw_circle(source, 8.0, LIGHT)
	draw_circle(source, 14.0, Color(LIGHT, 0.15))
	draw_circle(sink, 8.0, LIGHT if lit > junctions.size() else DARK)
