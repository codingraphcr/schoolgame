class_name DistrictLayout
extends Resource
## La parte fija de un distrito (data/world/districts/): sus salas obligatorias, en qué celda está
## cada una y cómo se conectan. Hoy todo el mapa es fijo; más adelante el generador (M4) parte de
## esto y cuelga las salas opcionales de las puertas que quedan libres.

@export var id: StringName = &""
@export var display_name := ""
## Sala por la que se entra al distrito.
@export var start_room: StringName = &""
@export var rooms: Array[LayoutRoom] = []
@export var links: Array[LayoutLink] = []


## Arma el grafo del distrito. null (y un error en la consola) si algo no encaja.
func build(templates: Dictionary[StringName, RoomTemplate]) -> RoomGraph:
	var graph := RoomGraph.new(id, templates)
	for room in rooms:
		if room == null or not graph.add_room(room.room_id, room.template_id, room.cell):
			push_error("DistrictLayout %s: no se pudo colocar la sala %s" % [id, room.room_id if room else &"?"])
			return null
	for edge in links:
		if edge == null:
			continue
		var error := graph.link_error(edge.room_a, edge.door_a, edge.room_b, edge.door_b)
		if not error.is_empty() or not graph.link(edge.room_a, edge.door_a, edge.room_b, edge.door_b, edge.requires, edge.one_way):
			push_error("DistrictLayout %s: %s.%s ↔ %s.%s: %s" % [id, edge.room_a, edge.door_a, edge.room_b, edge.door_b, error])
			return null
	if not graph.rooms.has(start_room):
		push_error("DistrictLayout %s: la sala de inicio %s no existe" % [id, start_room])
		return null
	return graph
