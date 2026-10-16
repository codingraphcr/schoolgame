@tool
class_name GrimorioMap
extends Control
## Mapa de una zona (distrito) en el Grimorio, dibujado con el mapa real de la partida (World: el
## grafo de salas y conexiones, incluidas las salas que armó el generador). Cada sala tiene un estado:
##
## - Desconocida: no se dibuja.
## - Descubierta: está conectada con una sala visitada (gris, sin nombre).
## - Se abre más adelante: descubierta, pero es de un capítulo que no empezó (rayada en rosa).
## - Visitada: Kai estuvo ahí (lila, con nombre).
## - Completada: visitada y con todas sus misiones terminadas (con una marca).
##
## Muestra también las conexiones entre salas (las escaleras con peldaños), las terminales, dónde
## está Kai y **a dónde ir por la misión** (QuestStep.room_id del objetivo actual): una marca dorada que
## late sobre esa sala (aunque todavía no se conozca) y arriba «MISIÓN: <sala>»; si la sala es de otra
## zona, lo dice. Una sala cuenta como visitada si está en World.visited o, en partidas anteriores al mapa,
## por la marca "visitada_<escena>" que deja Room al entrar.

enum State { UNKNOWN, DISCOVERED, LOCKED, VISITED, COMPLETED }

const MAX_CELL := 56.0
const LEGEND_HEIGHT := 74.0
const PANEL := Color("100c20")
const GRID := Color(0.5, 0.42, 0.85, 0.12)
const VISITED := Color("4b3be0")
const VISITED_EDGE := Color("b9a6ff")
const UNVISITED := Color("3a3550")
const LOCKED := Color("e0457b")
const DONE := Color("5dff9a")
const KAI := Color("3ef2ff")
const TEXT := Color("e6deff")
const MISSION := Color("ffd166")

@export var zone: StringName = &"colegio":
	set(value):
		zone = value
		queue_redraw()


## Salas visitadas (o completadas) y total de la zona: Vector2i(visitadas, total).
## La sala de esta zona que marca la misión actual, o vacío (sin misión o en otra zona).
func mission_room() -> StringName:
	var graph := _graph()
	var game_state := get_node_or_null("/root/GameState")
	if graph == null or game_state == null:
		return &""
	var target: StringName = game_state.get_objective_room()
	return target if graph.rooms.has(target) else &""


## Lo que se escribe arriba del mapa sobre la misión (vacío si no hay).
func mission_text() -> String:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or _world() == null:
		return ""
	var target: StringName = game_state.get_objective_room()
	if target == &"":
		return ""
	var graph := _graph()
	if graph and graph.rooms.has(target):
		return "MISIÓN: " + graph.template_of(target).display_name
	var district: StringName = _world().district_of(target)
	return "MISIÓN EN: " + String(_world().district_names.get(district, String(district)))


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and is_visible_in_tree() and not mission_text().is_empty():
		queue_redraw()  # La marca de la misión late.


func progress() -> Vector2i:
	var states := room_states()
	var visited := 0
	for room_id: StringName in states:
		if states[room_id] >= State.VISITED:
			visited += 1
	return Vector2i(visited, states.size())


## Estado de cada sala de la zona: room_id → State.
func room_states() -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	var graph := _graph()
	if graph == null:
		return result
	var game_state := get_node_or_null("/root/GameState")
	# El mapa comprado en la tienda de la soda («mapa_<zona>») muestra todas las salas de la zona.
	var bought_map: bool = game_state != null and game_state.has_flag(StringName("mapa_%s" % zone))
	for room_id: StringName in graph.rooms:
		if _is_visited(graph, room_id):
			result[room_id] = State.VISITED
		else:
			result[room_id] = State.DISCOVERED if bought_map else State.UNKNOWN
	for edge in graph.links:
		for pair in [[edge["a"], edge["b"]], [edge["b"], edge["a"]]]:
			if result[pair[0]] == State.VISITED and result[pair[1]] == State.UNKNOWN:
				result[pair[1]] = State.DISCOVERED
	var world := _world()
	for room_id: StringName in result:
		if result[room_id] == State.DISCOVERED and not String(world.lock_reason(room_id)).is_empty():
			result[room_id] = State.LOCKED
		elif result[room_id] == State.VISITED and game_state and _missions_done(graph.template_of(room_id), game_state):
			result[room_id] = State.COMPLETED
	return result


func _draw() -> void:
	var map_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.y - LEGEND_HEIGHT))
	draw_rect(map_rect, PANEL)
	draw_rect(map_rect, Color(VISITED_EDGE, 0.6), false, 2.0)
	var font := get_theme_default_font()
	var graph := _graph()
	var states := room_states()
	var cell := _cell_size(graph, map_rect)
	var x := cell
	while x < map_rect.size.x:
		draw_line(Vector2(x, 0), Vector2(x, map_rect.size.y), GRID, 1.0)
		x += cell
	var y := cell
	while y < map_rect.size.y:
		draw_line(Vector2(0, y), Vector2(map_rect.size.x, y), GRID, 1.0)
		y += cell
	if graph:
		var bounds := _bounds(graph)
		var origin := map_rect.get_center() - Vector2(bounds.size) * cell / 2.0 - Vector2(bounds.position) * cell
		for edge in graph.links:
			if states[edge["a"]] != State.UNKNOWN and states[edge["b"]] != State.UNKNOWN:
				_draw_link(graph, edge, origin, cell)
		for room_id: StringName in graph.rooms:
			if states[room_id] != State.UNKNOWN:
				_draw_room(graph, room_id, states[room_id], origin, cell, font)
		var target := mission_room()
		if target != &"":
			_draw_mission(_room_rect(graph, target, origin, cell), states[target] == State.UNKNOWN)
		var mission := mission_text()
		if not mission.is_empty():
			draw_string(font, Vector2(10.0, 22.0), mission, HORIZONTAL_ALIGNMENT_LEFT, map_rect.size.x * 0.6, 13, MISSION)
		var title := String(_world().district_names.get(zone, String(zone))).to_upper()
		draw_string(font, Vector2(0, 22.0), title, HORIZONTAL_ALIGNMENT_RIGHT, map_rect.size.x - 10.0, 14, TEXT)
		draw_string(font, Vector2(0, 38.0), "%d%%" % _percent(progress()), HORIZONTAL_ALIGNMENT_RIGHT, map_rect.size.x - 10.0, 11, Color(TEXT, 0.6))
	_draw_legend(Vector2(0, map_rect.end.y + 6.0), font)


func _draw_room(graph: RoomGraph, room_id: StringName, state: int, origin: Vector2, cell: float, font: Font) -> void:
	var template := graph.template_of(room_id)
	var rect := _room_rect(graph, room_id, origin, cell)
	match state:
		State.LOCKED:
			_draw_unknown(rect)
			_draw_lock(rect.get_center(), Color(LOCKED, 0.9))
		State.DISCOVERED:
			draw_rect(rect, UNVISITED)
			draw_rect(rect, Color(TEXT, 0.25), false, 2.0)
			draw_string(font, rect.get_center() + Vector2(-4, 4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(TEXT, 0.5))
		_:
			draw_rect(rect, VISITED)
			draw_rect(rect, VISITED_EDGE, false, 2.0)
			_draw_name(font, template.display_name, rect)
			if template.has_terminal:
				_draw_terminal(rect.end - Vector2(12, 10), TEXT)
			if state == State.COMPLETED:
				_draw_check(Vector2(rect.position.x + 10, rect.end.y - 9), DONE)
	if room_id == _world().current_room:
		_draw_kai(Vector2(rect.get_center().x, rect.end.y - 9.0))


## Nombre de la sala, en varias líneas si hace falta y con la letra más grande en la que quepa cada
## palabra (las salas de una celda son angostas).
func _draw_name(font: Font, text: String, rect: Rect2) -> void:
	var width := rect.size.x - 6.0
	var font_size := 10
	for word in text.split(" "):
		while font_size > 7 and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			font_size -= 1
	draw_multiline_string(font, rect.position + Vector2(3, font_size + 2), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, 2, TEXT)


## Conexión entre dos salas: un puente corto sobre el borde que comparten (con peldaños si es escalera).
func _draw_link(graph: RoomGraph, edge: Dictionary, origin: Vector2, cell: float) -> void:
	var spec: DoorSpec = graph.template_of(edge["a"]).door(edge["door_a"])
	if spec == null:
		return
	var from_cell := graph.door_cell(edge["a"], edge["door_a"])
	var center := origin + (Vector2(from_cell) + Vector2(0.5, 0.5)) * cell + Vector2(DoorSpec.step(spec.side)) * cell * 0.5
	var color := Color(VISITED_EDGE, 0.85)
	if DoorSpec.is_vertical(spec.kind):
		for side in [-1.0, 1.0]:
			draw_line(center + Vector2(side * 4.0, -7.0), center + Vector2(side * 4.0, 7.0), color, 1.5)
		for k in 3:
			draw_line(center + Vector2(-4.0, -4.0 + k * 4.0), center + Vector2(4.0, -4.0 + k * 4.0), color, 1.0)
	else:
		draw_rect(Rect2(center - Vector2(5, 3), Vector2(10, 6)), color)


func _draw_legend(at: Vector2, font: Font) -> void:
	var rows := [
		[VISITED, "Visitada"], [UNVISITED, "Sin visitar"], ["done", "Completada"], ["mission", "Misión"],
		["terminal", "Terminal"], ["locked", "Más adelante"], ["kai", "Estás aquí"],
	]
	var columns := 4
	draw_rect(Rect2(at, Vector2(size.x, LEGEND_HEIGHT - 6.0)), PANEL)
	for i in rows.size():
		var cell := at + Vector2(12.0 + (i % columns) * size.x / columns, 10.0 + (i / columns) * 26.0)
		var mark: Variant = rows[i][0]
		if mark is Color:
			draw_rect(Rect2(cell, Vector2(14, 14)), mark)
		elif mark == "terminal":
			_draw_terminal(cell + Vector2(7, 7), TEXT)
		elif mark == "done":
			_draw_check(cell + Vector2(7, 7), DONE)
		elif mark == "kai":
			_draw_kai(cell + Vector2(7, 7))
		elif mark == "mission":
			_draw_pin(cell + Vector2(7, 7), 1.0)
		else:
			_draw_unknown(Rect2(cell, Vector2(14, 14)))
		draw_string(font, cell + Vector2(22, 12), rows[i][1], HORIZONTAL_ALIGNMENT_LEFT, size.x / columns - 30.0, 11, TEXT)


## Rayado en rosa (zona que todavía no se puede visitar).
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


func _draw_check(center: Vector2, color: Color) -> void:
	draw_polyline(PackedVector2Array([center + Vector2(-5, 0), center + Vector2(-1, 4), center + Vector2(6, -4)]), color, 2.0)


func _draw_lock(center: Vector2, color: Color) -> void:
	draw_rect(Rect2(center - Vector2(5, 1), Vector2(10, 8)), color)
	draw_arc(center + Vector2(0, -1), 3.5, PI, TAU, 8, color, 1.5)


## A dónde ir: borde dorado que late (punteado si la sala todavía no se conoce) y un alfiler con «!».
func _draw_mission(rect: Rect2, unknown: bool) -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
	if unknown:
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for k in 4:
			draw_dashed_line(corners[k], corners[(k + 1) % 4], Color(MISSION, 0.8), 2.0, 5.0)
	else:
		draw_rect(rect.grow(2.0 + pulse * 2.0), Color(MISSION, 0.35 + 0.4 * pulse), false, 2.0)
	_draw_pin(Vector2(rect.end.x - 2.0, rect.position.y + 2.0), 1.0 + 0.15 * pulse)


func _draw_pin(center: Vector2, grow: float) -> void:
	draw_circle(center, 7.0 * grow, MISSION)
	draw_circle(center, 7.0 * grow, Color(0.1, 0.06, 0.02), false, 1.0)
	draw_line(center + Vector2(0, -4), center + Vector2(0, 1), Color(0.1, 0.06, 0.02), 2.0)
	draw_circle(center + Vector2(0, 3.5), 1.1, Color(0.1, 0.06, 0.02))


## Kai: un rombo cian.
func _draw_kai(center: Vector2) -> void:
	var points := PackedVector2Array([center + Vector2(0, -6), center + Vector2(5, 0), center + Vector2(0, 6), center + Vector2(-5, 0)])
	draw_colored_polygon(points, KAI)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.0)


func _room_rect(graph: RoomGraph, room_id: StringName, origin: Vector2, cell: float) -> Rect2:
	var template := graph.template_of(room_id)
	var cell_origin: Vector2i = graph.rooms[room_id]["cell"]
	return Rect2(origin + Vector2(cell_origin) * cell, Vector2(template.size_cells) * cell).grow(-4.0)


## Celdas que ocupa la zona (todas sus salas, descubiertas o no: así el mapa no se mueve al explorar).
func _bounds(graph: RoomGraph) -> Rect2i:
	var bounds := Rect2i()
	var first := true
	for room_id: StringName in graph.rooms:
		var rect := Rect2i(graph.rooms[room_id]["cell"], graph.template_of(room_id).size_cells)
		bounds = rect if first else bounds.merge(rect)
		first = false
	return bounds


func _cell_size(graph: RoomGraph, map_rect: Rect2) -> float:
	if graph == null:
		return 24.0
	var bounds := _bounds(graph)
	var room := map_rect.size - Vector2(48, 72)
	return clampf(minf(room.x / maxf(bounds.size.x, 1), room.y / maxf(bounds.size.y, 1)), 16.0, MAX_CELL)


func _is_visited(graph: RoomGraph, room_id: StringName) -> bool:
	if _world().visited.has(room_id):
		return true
	var template := graph.template_of(room_id)
	var game_state := get_node_or_null("/root/GameState")
	return template.fixed and game_state != null \
		and game_state.has_flag(StringName("visitada_" + template.scene_path.get_file().get_basename()))


## Si la sala tiene misiones y todas están terminadas.
func _missions_done(template: RoomTemplate, game_state: Node) -> bool:
	if template.mission_ids.is_empty():
		return false
	for quest_id in template.mission_ids:
		if not game_state.is_quest_completed(StringName(quest_id)):
			return false
	return true


func _world() -> Node:
	return get_node_or_null("/root/World")


func _graph() -> RoomGraph:
	if Engine.is_editor_hint() or _world() == null:
		return null
	return _world().graph(zone)


func _percent(value: Vector2i) -> int:
	return roundi(100.0 * value.x / maxi(value.y, 1))
