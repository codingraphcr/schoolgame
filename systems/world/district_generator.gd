class_name DistrictGenerator
extends RefCounted
## El generador del mapa (M4): arma un distrito a partir de su parte fija (DistrictLayout) y la
## semilla de la partida. Mismo distrito + misma semilla + misma versión = el mismo mapa, siempre.
##
## A · Estructura fija: las salas y conexiones obligatorias del DistrictLayout, tal cual.
## B · Conectividad: desde la sala de inicio se llega a todas las salas obligatorias; las del
##     prólogo (capítulo 0), sin ninguna habilidad. (Las salas de capítulos posteriores las abre
##     World al llegar a ese capítulo.)
## C · Salas opcionales: de las puertas que quedan libres se cuelgan salas de la biblioteca de
##     plantillas (no fijas, no secretas, del mismo distrito), elegidas al azar según su peso, sin
##     chocar con otras salas y solo entre puertas enfrentadas y compatibles. Una opcional puede abrir
##     otra, hasta optional_rooms salas. Las puertas que quedan libres al final quedan cerradas.
## F · Validación: conexiones, compatibilidad de puertas, salas obligatorias alcanzables, bloqueos
##     por habilidades, que no queden salas sueltas, distancias razonables y que cada puerta usada
##     tenga su punto de aparición. Si falla, se rearma solo la parte variable con otra tirada; la
##     parte fija nunca se toca. Si se agotan los intentos, queda solo la parte fija (validada).
## D (secretos) y E (contenido: enemigos, terminales, coleccionables) llegan después.

## Versión del algoritmo. Si cambia la forma de elegir salas, sube (World.GENERATOR_VERSION).
const VERSION := 1
const ATTEMPTS := 8
const ALL_ABILITIES: PackedStringArray = ["dash", "double_jump", "wall_jump", "vision"]
## Una sala opcional nunca queda a más de estas puertas de una sala obligatoria.
const MAX_DEPTH := 3

## Problemas de la última validación que falló (vacío si salió bien al primer intento).
var errors: PackedStringArray = []
## Cuántas tiradas hizo la última generación.
var attempts_used := 0
## Si la última generación terminó en la distribución de respaldo (solo la parte fija).
var used_fallback := false


## Arma el distrito. null solo si la parte fija está mal (error de datos, se avisa en la consola).
func generate(layout: DistrictLayout, templates: Dictionary[StringName, RoomTemplate], seed_value: int) -> RoomGraph:
	errors = []
	attempts_used = 0
	used_fallback = false
	var fixed := layout.build(templates)
	if fixed == null:
		return null
	var problems := validate(fixed, layout)
	if not problems.is_empty():
		push_error("DistrictGenerator %s: la parte fija no pasa la validación: %s" % [layout.id, problems])
		errors = problems
		return null
	var pool := optional_pool(layout, templates)
	if layout.optional_rooms <= 0 or pool.is_empty():
		return fixed
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%s|%d" % [seed_value, layout.id, VERSION])
	for attempt in ATTEMPTS:
		attempts_used = attempt + 1
		var graph := layout.build(templates)
		_add_optional_rooms(graph, layout, pool, rng)
		problems = validate(graph, layout)
		if problems.is_empty():
			return graph
		errors = problems
	used_fallback = true
	return fixed


## Plantillas que pueden aparecer como salas opcionales en el distrito (en orden estable).
static func optional_pool(layout: DistrictLayout, templates: Dictionary[StringName, RoomTemplate]) -> Array[RoomTemplate]:
	var pool: Array[RoomTemplate] = []
	var ids := templates.keys()
	ids.sort()
	for id: StringName in ids:
		var template: RoomTemplate = templates[id]
		if not template.fixed and not template.secret_room and template.district_id == layout.id and template.generation_weight > 0.0:
			pool.append(template)
	return pool


## Fase F: los problemas del grafo (vacío = válido).
func validate(graph: RoomGraph, layout: DistrictLayout) -> PackedStringArray:
	var problems: PackedStringArray = []
	if not graph.rooms.has(layout.start_room):
		problems.append("falta la sala de inicio %s" % layout.start_room)
		return problems
	var everything := graph.reachable(layout.start_room, ALL_ABILITIES)
	var without := graph.reachable(layout.start_room, PackedStringArray())
	var fixed_ids := {}
	for room in layout.rooms:
		fixed_ids[room.room_id] = true
	for room_id: StringName in graph.rooms:
		var template := graph.template_of(room_id)
		if not everything.has(room_id):
			problems.append("no se llega a %s" % room_id)
		elif fixed_ids.has(room_id) and template.chapter_requirement == 0 and not without.has(room_id):
			problems.append("%s es del prólogo y pide habilidades" % room_id)
		if template.scene_path.is_empty():
			problems.append("%s no tiene escena" % room_id)
		if not fixed_ids.has(room_id) and _depth(graph, room_id, fixed_ids) > MAX_DEPTH:
			problems.append("%s queda demasiado lejos" % room_id)
	for edge in graph.links:
		for side in [["a", "door_a"], ["b", "door_b"]]:
			var spec: DoorSpec = graph.template_of(edge[side[0]]).door(edge[side[1]])
			if spec == null or spec.entry_id == &"":
				problems.append("%s.%s no tiene punto de aparición" % [edge[side[0]], edge[side[1]]])
		var spec_a: DoorSpec = graph.template_of(edge["a"]).door(edge["door_a"])
		var spec_b: DoorSpec = graph.template_of(edge["b"]).door(edge["door_b"])
		if spec_a and spec_b and (spec_b.side != DoorSpec.opposite(spec_a.side) or not DoorSpec.kinds_match(spec_a.kind, spec_b.kind)
				or graph.door_cell(edge["a"], edge["door_a"]) + DoorSpec.step(spec_a.side) != graph.door_cell(edge["b"], edge["door_b"])):
			problems.append("%s.%s y %s.%s no encajan" % [edge["a"], edge["door_a"], edge["b"], edge["door_b"]])
	return problems


## Fase C: cuelga salas opcionales de las puertas libres hasta optional_rooms.
func _add_optional_rooms(graph: RoomGraph, layout: DistrictLayout, pool: Array[RoomTemplate], rng: RandomNumberGenerator) -> void:
	var placed := 0
	while placed < layout.optional_rooms:
		var doors := graph.open_doors()
		_shuffle(doors, rng)
		var done := false
		for open in doors:
			var choice := _pick(graph, open, pool, rng)
			if choice.is_empty():
				continue
			var template: RoomTemplate = choice["template"]
			var room_id := StringName("%s_%d" % [template.id, placed + 1])
			if graph.add_room(room_id, template.id, choice["origin"]) and graph.link(open["room"], open["door"], room_id, choice["door"]):
				placed += 1
				done = true
				break
		if not done:
			return


## Una plantilla (por peso) que encaje en esa puerta libre: { template, door, origin } o {}.
func _pick(graph: RoomGraph, open: Dictionary, pool: Array[RoomTemplate], rng: RandomNumberGenerator) -> Dictionary:
	var open_spec: DoorSpec = graph.template_of(open["room"]).door(open["door"])
	var target_cell := graph.door_cell(open["room"], open["door"]) + DoorSpec.step(open_spec.side)
	var options: Array[Dictionary] = []
	var total := 0.0
	for template in pool:
		for spec in template.doors:
			if spec.side != DoorSpec.opposite(open_spec.side) or not DoorSpec.kinds_match(open_spec.kind, spec.kind):
				continue
			var origin := target_cell - spec.cell
			if graph.fits(template, origin):
				options.append({ "template": template, "door": spec.id, "origin": origin })
				total += template.generation_weight
	if options.is_empty():
		return {}
	var roll := rng.randf() * total
	for option in options:
		roll -= (option["template"] as RoomTemplate).generation_weight
		if roll <= 0.0:
			return option
	return options.back()


## Cuántas puertas hay desde la sala hasta la sala obligatoria más cercana.
func _depth(graph: RoomGraph, room_id: StringName, fixed_ids: Dictionary) -> int:
	var best := 1 << 20
	for fixed_id: StringName in fixed_ids:
		var path := graph.find_path(fixed_id, room_id, ALL_ABILITIES)
		if not path.is_empty():
			best = mini(best, path.size() - 1)
	return best


func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap
