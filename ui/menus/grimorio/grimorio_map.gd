@tool
class_name GrimorioMap
extends Control
## Mapa esquemático de una zona en el Grimorio: las salas visitadas en lila, las conocidas sin
## visitar en gris y las que todavía no se descubrieron rayadas («???»). Debajo, la leyenda.
## Una sala cuenta como visitada por la marca "visitada_<escena>" que deja Room al entrar, o
## por haber llegado a un paso de una misión (para lugares dentro de una misma escena).

const CELL := 24.0
const PANEL := Color("100c20")
const GRID := Color(0.5, 0.42, 0.85, 0.12)
const VISITED := Color("4b3be0")
const VISITED_EDGE := Color("b9a6ff")
const UNVISITED := Color("3a3550")
const LOCKED := Color("e0457b")
const TEXT := Color("e6deff")

## Salas de cada zona: rect en celdas, nombre y cómo se sabe si se visitó.
const ZONES := {
	&"colegio": [
		{ "name": "Entrada", "rect": Rect2(1, 5, 4, 2), "flag": &"visitada_entrada" },
		{ "name": "Pasillo", "rect": Rect2(5, 5, 6, 1), "flag": &"visitada_pasillo_laboratorio" },
		{ "name": "Laboratorio", "rect": Rect2(11, 4, 3, 2), "flag": &"visitada_pasillo_laboratorio", "terminal": true },
		{ "name": "???", "rect": Rect2(2, 1, 3, 3) },
		{ "name": "???", "rect": Rect2(7, 1, 4, 3) },
		{ "name": "???", "rect": Rect2(14, 6, 3, 2) },
		{ "name": "???", "rect": Rect2(6, 7, 3, 2) },
	],
	&"pc_profesor": [
		{ "name": "Escritorio", "rect": Rect2(1, 3, 4, 2), "flag": &"visitada_escritorio", "terminal": true },
		{ "name": "Bandeja de SPAM", "rect": Rect2(5, 3, 8, 1), "quest": &"contrasena_profesor", "step": &"cambiar_contrasena" },
		{ "name": "Cuenta del profesor", "rect": Rect2(13, 2, 3, 3), "quest": &"contrasena_profesor", "step": &"cambiar_contrasena", "terminal": true },
		{ "name": "???", "rect": Rect2(3, 6, 4, 2) },
		{ "name": "???", "rect": Rect2(10, 6, 4, 2) },
	],
}

@export var zone: StringName = &"colegio":
	set(value):
		zone = value
		queue_redraw()


## Salas visitadas y total de la zona: Vector2i(visitadas, total).
func progress() -> Vector2i:
	var rooms: Array = ZONES.get(zone, [])
	var visited := 0
	for room: Dictionary in rooms:
		if _is_visited(room):
			visited += 1
	return Vector2i(visited, rooms.size())


func _draw() -> void:
	var map_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.y - 74.0))
	draw_rect(map_rect, PANEL)
	draw_rect(map_rect, Color(VISITED_EDGE, 0.6), false, 2.0)
	var x := CELL
	while x < map_rect.size.x:
		draw_line(Vector2(x, 0), Vector2(x, map_rect.size.y), GRID, 1.0)
		x += CELL
	var y := CELL
	while y < map_rect.size.y:
		draw_line(Vector2(0, y), Vector2(map_rect.size.x, y), GRID, 1.0)
		y += CELL
	var font := get_theme_default_font()
	var origin := Vector2(CELL * 0.5, CELL * 0.5)
	for room: Dictionary in ZONES.get(zone, []):
		var rect := Rect2(origin + room["rect"].position * CELL, room["rect"].size * CELL)
		if room["name"] == "???":
			_draw_unknown(rect)
			continue
		var visited := _is_visited(room)
		draw_rect(rect, VISITED if visited else UNVISITED)
		draw_rect(rect, VISITED_EDGE if visited else Color(TEXT, 0.25), false, 2.0)
		if visited:
			draw_string(font, rect.position + Vector2(4, 13), room["name"], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 6.0, 10, TEXT)
		if room.get("terminal", false):
			_draw_terminal(rect.end - Vector2(12, 10), TEXT if visited else Color(TEXT, 0.4))
	# Título de la zona.
	var progress_now := progress()
	var title := "COLEGIO" if zone == &"colegio" else "COMPUTADORA"
	draw_string(font, Vector2(0, 22.0), title, HORIZONTAL_ALIGNMENT_RIGHT, map_rect.size.x - 10.0, 14, TEXT)
	draw_string(font, Vector2(0, 38.0), "%d%%" % _percent(progress_now), HORIZONTAL_ALIGNMENT_RIGHT, map_rect.size.x - 10.0, 11, Color(TEXT, 0.6))
	_draw_legend(Vector2(0, map_rect.end.y + 10.0), font)


func _draw_legend(at: Vector2, font: Font) -> void:
	var rows := [
		[VISITED, "Sala visitada"], [UNVISITED, "Sala no visitada"],
		["terminal", "Terminal"], ["locked", "Zona sin descubrir"],
	]
	draw_rect(Rect2(at, Vector2(size.x, 64.0)), PANEL)
	for i in rows.size():
		var cell := at + Vector2(14.0 + (i % 2) * size.x * 0.5, 12.0 + (i / 2) * 26.0)
		var mark: Variant = rows[i][0]
		if mark is Color:
			draw_rect(Rect2(cell, Vector2(14, 14)), mark)
		elif mark == "terminal":
			_draw_terminal(cell + Vector2(7, 7), TEXT)
		else:
			_draw_unknown(Rect2(cell, Vector2(14, 14)))
		draw_string(font, cell + Vector2(24, 12), rows[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT)


## Sala sin descubrir: rayada en rosa.
func _draw_unknown(rect: Rect2) -> void:
	draw_rect(rect, Color(UNVISITED, 0.5))
	var box := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var offset := 0.0
	while offset < rect.size.x + rect.size.y:
		var line := PackedVector2Array([rect.position + Vector2(offset, 0), rect.position + Vector2(offset - rect.size.y, rect.size.y)])
		for piece in Geometry2D.intersect_polyline_with_polygon(line, box):
			draw_polyline(piece, Color(LOCKED, 0.55), 1.0)
		offset += 6.0
	draw_rect(rect, Color(LOCKED, 0.5), false, 1.0)


func _draw_terminal(center: Vector2, color: Color) -> void:
	draw_rect(Rect2(center - Vector2(6, 5), Vector2(12, 8)), color, false, 1.5)
	draw_line(center + Vector2(-3, 5), center + Vector2(3, 5), color, 1.5)


func _is_visited(room: Dictionary) -> bool:
	if Engine.is_editor_hint():
		return room.has("flag")
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	if room.has("flag"):
		return game_state.has_flag(room["flag"])
	if room.has("quest"):
		return game_state.has_reached_step(room["quest"], room["step"])
	return false


func _percent(value: Vector2i) -> int:
	return roundi(100.0 * value.x / maxi(value.y, 1))
