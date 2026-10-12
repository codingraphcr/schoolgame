class_name RoomGraph
extends RefCounted
## El mapa de un distrito como grafo: qué salas hay, en qué celda de la cuadrícula está cada una y
## qué puerta conecta con cuál. Es solo navegación (sin escenas): lo arma el generador, lo guarda la
## partida, lo dibuja el Grimorio y lo consulta la sala para saber a dónde lleva cada puerta.
##
## Una conexión solo se acepta si las puertas quedan enfrentadas (celdas vecinas, lados opuestos) y
## son de clases compatibles. Puede pedir habilidades para cruzarla (p. ej. &"double_jump") y ser de
## un solo sentido (un atajo). Un paso secreto pide además la Visión Digital (&"vision").
##
## Habilidades: &"dash", &"double_jump", &"wall_jump", &"vision" (ver abilities_of()).

const VERSION := 1
const VISION := &"vision"

var district_id: StringName = &""
## room_id → { "template": StringName, "cell": Vector2i }
var rooms: Dictionary[StringName, Dictionary] = {}
## Cada conexión: { "a", "door_a", "b", "door_b", "requires": PackedStringArray, "one_way": bool }
var links: Array[Dictionary] = []

var _templates: Dictionary[StringName, RoomTemplate] = {}
## Celda ocupada → room_id
var _cells: Dictionary[Vector2i, StringName] = {}


func _init(district: StringName = &"", templates: Dictionary[StringName, RoomTemplate] = {}) -> void:
	district_id = district
	_templates = templates


func template_of(room_id: StringName) -> RoomTemplate:
	if not rooms.has(room_id):
		return null
	return _templates.get(rooms[room_id]["template"])


func room_at(cell: Vector2i) -> StringName:
	return _cells.get(cell, &"")


## Si la plantilla cabe en esa celda sin chocar con otra sala.
func fits(template: RoomTemplate, origin: Vector2i) -> bool:
	for cell in template.cells_at(origin):
		if _cells.has(cell):
			return false
	return true


## Coloca una sala. false si el id ya existe, la plantilla no se conoce o choca con otra sala.
func add_room(room_id: StringName, template_id: StringName, origin: Vector2i) -> bool:
	var template: RoomTemplate = _templates.get(template_id)
	if room_id == &"" or rooms.has(room_id) or template == null or not fits(template, origin):
		return false
	rooms[room_id] = { "template": template_id, "cell": origin }
	for cell in template.cells_at(origin):
		_cells[cell] = room_id
	return true


## Celda del mapa (absoluta) donde está esa puerta de la sala.
func door_cell(room_id: StringName, door_id: StringName) -> Vector2i:
	var spec := _door(room_id, door_id)
	if spec == null:
		return Vector2i.ZERO
	var origin: Vector2i = rooms[room_id]["cell"]
	return origin + spec.cell


## Por qué no se pueden conectar esas puertas ("" si sí se puede).
func link_error(a: StringName, door_a: StringName, b: StringName, door_b: StringName) -> String:
	var spec_a := _door(a, door_a)
	var spec_b := _door(b, door_b)
	if spec_a == null or spec_b == null:
		return "no existe la puerta %s.%s o %s.%s" % [a, door_a, b, door_b]
	if a == b:
		return "una sala no se conecta consigo misma"
	if is_linked(a, door_a) or is_linked(b, door_b):
		return "esa puerta ya está conectada"
	if spec_b.side != DoorSpec.opposite(spec_a.side):
		return "las puertas no quedan enfrentadas"
	if door_cell(a, door_a) + DoorSpec.step(spec_a.side) != door_cell(b, door_b):
		return "las puertas no están en celdas vecinas"
	if not DoorSpec.kinds_match(spec_a.kind, spec_b.kind):
		return "las clases de puerta no son compatibles"
	return ""


## Conecta dos puertas. requires: habilidades para cruzar. one_way: solo de a hacia b.
func link(a: StringName, door_a: StringName, b: StringName, door_b: StringName,
		requires: PackedStringArray = [], one_way := false) -> bool:
	var error := link_error(a, door_a, b, door_b)
	if not error.is_empty():
		return false
	var needs := requires.duplicate()
	var secret := _door(a, door_a).kind == DoorSpec.Kind.SECRET or _door(b, door_b).kind == DoorSpec.Kind.SECRET
	if secret and not needs.has(VISION):
		needs.append(VISION)
	links.append({ "a": a, "door_a": door_a, "b": b, "door_b": door_b, "requires": needs, "one_way": one_way })
	return true


func is_linked(room_id: StringName, door_id: StringName) -> bool:
	return not target_of(room_id, door_id).is_empty()


## A dónde lleva una puerta: { "room", "door" } o {} si no está conectada.
func target_of(room_id: StringName, door_id: StringName) -> Dictionary:
	for edge in links:
		if edge["a"] == room_id and edge["door_a"] == door_id:
			return { "room": edge["b"], "door": edge["door_b"] }
		if edge["b"] == room_id and edge["door_b"] == door_id:
			return { "room": edge["a"], "door": edge["door_a"] }
	return {}


## Puertas sin conectar: [{ "room", "door" }], en orden estable.
func open_doors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for room_id in _sorted_rooms():
		for spec in template_of(room_id).doors:
			if not is_linked(room_id, spec.id):
				result.append({ "room": room_id, "door": spec.id })
	return result


## Salas a las que se llega desde start con esas habilidades (incluye start).
func reachable(start: StringName, abilities: PackedStringArray) -> Array[StringName]:
	var result: Array[StringName] = []
	if not rooms.has(start):
		return result
	var seen: Dictionary[StringName, bool] = { start: true }
	var queue: Array[StringName] = [start]
	while not queue.is_empty():
		var current: StringName = queue.pop_front()
		result.append(current)
		for next in _neighbors(current, abilities):
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return result


## Camino más corto (en salas) de from a to con esas habilidades; [] si no se puede llegar.
func find_path(from: StringName, to: StringName, abilities: PackedStringArray) -> Array[StringName]:
	var path: Array[StringName] = []
	if not rooms.has(from) or not rooms.has(to):
		return path
	var came_from: Dictionary[StringName, StringName] = { from: &"" }
	var queue: Array[StringName] = [from]
	while not queue.is_empty():
		var current: StringName = queue.pop_front()
		if current == to:
			break
		for next in _neighbors(current, abilities):
			if not came_from.has(next):
				came_from[next] = current
				queue.append(next)
	if not came_from.has(to):
		return path
	var step := to
	while step != &"":
		path.push_front(step)
		step = came_from[step]
	return path


## Habilidades que tiene Kai según GameState (para reachable / find_path).
static func abilities_of(state: Node) -> PackedStringArray:
	var result: PackedStringArray = []
	if state.dash_level > 0:
		result.append("dash")
	if state.can_double_jump:
		result.append("double_jump")
	if state.can_wall_jump:
		result.append("wall_jump")
	if state.vision_unlocked:
		result.append(VISION)
	return result


func to_dict() -> Dictionary:
	var room_data := {}
	for room_id in _sorted_rooms():
		var cell: Vector2i = rooms[room_id]["cell"]
		room_data[String(room_id)] = { "template": String(rooms[room_id]["template"]), "cell": [cell.x, cell.y] }
	var link_data: Array = []
	for edge in links:
		link_data.append({ "a": String(edge["a"]), "door_a": String(edge["door_a"]), "b": String(edge["b"]),
			"door_b": String(edge["door_b"]), "requires": Array(edge["requires"]), "one_way": edge["one_way"] })
	return { "version": VERSION, "district": String(district_id), "rooms": room_data, "links": link_data }


## Rearma un grafo guardado (también desde JSON). null si los datos no sirven: versión
## desconocida, plantillas que ya no existen o conexiones que ya no encajan.
static func from_dict(data: Dictionary, templates: Dictionary[StringName, RoomTemplate]) -> RoomGraph:
	if int(data.get("version", 0)) != VERSION or not data.get("rooms") is Dictionary or not data.get("links") is Array:
		return null
	var graph := RoomGraph.new(StringName(str(data.get("district", ""))), templates)
	var room_data: Dictionary = data["rooms"]
	var room_ids := room_data.keys()
	room_ids.sort()
	for room_id: Variant in room_ids:
		var entry: Variant = room_data[room_id]
		if not entry is Dictionary or not entry.get("cell") is Array or entry["cell"].size() != 2:
			return null
		var cell := Vector2i(int(entry["cell"][0]), int(entry["cell"][1]))
		if not graph.add_room(StringName(str(room_id)), StringName(str(entry.get("template", ""))), cell):
			return null
	for edge: Variant in data["links"]:
		if not edge is Dictionary:
			return null
		var requires := PackedStringArray(edge.get("requires", []))
		if not graph.link(StringName(str(edge.get("a", ""))), StringName(str(edge.get("door_a", ""))),
				StringName(str(edge.get("b", ""))), StringName(str(edge.get("door_b", ""))), requires, bool(edge.get("one_way", false))):
			return null
	return graph


func _door(room_id: StringName, door_id: StringName) -> DoorSpec:
	var template := template_of(room_id)
	return template.door(door_id) if template else null


func _neighbors(room_id: StringName, abilities: PackedStringArray) -> Array[StringName]:
	var result: Array[StringName] = []
	for edge in links:
		var next: StringName = &""
		if edge["a"] == room_id:
			next = edge["b"]
		elif edge["b"] == room_id and not edge["one_way"]:
			next = edge["a"]
		if next == &"" or not _has_all(abilities, edge["requires"]):
			continue
		if not _has_all(abilities, template_of(next).minimum_player_abilities):
			continue
		result.append(next)
	return result


func _sorted_rooms() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(rooms.keys())
	ids.sort_custom(func(x: StringName, y: StringName) -> bool: return String(x) < String(y))
	return ids


static func _has_all(abilities: PackedStringArray, needed: PackedStringArray) -> bool:
	for ability in needed:
		if not abilities.has(ability):
			return false
	return true
