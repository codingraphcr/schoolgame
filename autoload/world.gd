extends Node
## El mapa del mundo: los grafos de los distritos (RoomGraph) y en qué sala está Kai.
##
## Hoy cada distrito es fijo (DistrictLayout en data/world/districts/); más adelante el generador
## (M4) armará la parte variable y la partida guardará el grafo (M6).
##
## Las salas (Room) avisan al entrar con enter(); las salidas (RoomExit) preguntan a dónde lleva su
## puerta con destination(). Si una sala o una puerta no está en el mapa, siguen funcionando como
## antes (con su target_scene).
##
## Uso: World.current_room · World.destination(&"entrada", &"este") · World.room_entered

signal room_entered(room_id: StringName, district_id: StringName)

const ROOMS_FOLDER := "res://data/world/rooms"
const DISTRICTS_FOLDER := "res://data/world/districts"

var templates: Dictionary[StringName, RoomTemplate] = {}
## district_id → RoomGraph
var districts: Dictionary[StringName, RoomGraph] = {}
var current_room: StringName = &""
var current_district: StringName = &""

## room_id → district_id
var _room_district: Dictionary[StringName, StringName] = {}


func _ready() -> void:
	reset()


## Vuelve a armar el mapa desde los datos (partida nueva).
func reset() -> void:
	templates = RoomTemplate.load_folder(ROOMS_FOLDER)
	districts.clear()
	_room_district.clear()
	current_room = &""
	current_district = &""
	var files := Array(ResourceLoader.list_directory(DISTRICTS_FOLDER))
	files.sort()
	for file: String in files:
		var layout := load(DISTRICTS_FOLDER.path_join(file)) as DistrictLayout if file.ends_with(".tres") else null
		if layout == null:
			continue
		var graph := layout.build(templates)
		if graph:
			_add_district(graph)


func graph(district_id: StringName) -> RoomGraph:
	return districts.get(district_id)


func district_of(room_id: StringName) -> StringName:
	return _room_district.get(room_id, &"")


func template_of(room_id: StringName) -> RoomTemplate:
	var district := graph(district_of(room_id))
	return district.template_of(room_id) if district else null


## Escena de una sala del mapa ("" si no se conoce).
func scene_of(room_id: StringName) -> String:
	var template := template_of(room_id)
	return template.scene_path if template else ""


## Sala del mapa que usa esa escena (&"" si ninguna). Si varias la usan, la primera por id.
func room_for_scene(scene_path: String) -> StringName:
	var ids: Array[StringName] = []
	ids.assign(_room_district.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for room_id in ids:
		if scene_of(room_id) == scene_path:
			return room_id
	return &""


## La sala avisa que Kai entró. hint: el room_id con que se llegó (si se conoce); si no, se busca
## por la escena. Devuelve el room_id (&"" si la escena no está en el mapa).
func enter(scene_path: String, hint: StringName = &"") -> StringName:
	var room_id := hint if not hint.is_empty() and scene_of(hint) == scene_path else room_for_scene(scene_path)
	current_room = room_id
	current_district = district_of(room_id)
	if room_id != &"":
		room_entered.emit(room_id, current_district)
	return room_id


## A dónde lleva una puerta: { "room", "scene", "entry" } o {} si el mapa no lo sabe.
func destination(room_id: StringName, door_id: StringName) -> Dictionary:
	var district := graph(district_of(room_id))
	if district == null or door_id.is_empty():
		return {}
	var target := district.target_of(room_id, door_id)
	if target.is_empty():
		return {}
	var target_room: StringName = target["room"]
	var spec := district.template_of(target_room).door(target["door"])
	return { "room": target_room, "scene": scene_of(target_room), "entry": spec.entry_id }


func _add_district(district: RoomGraph) -> void:
	for room_id: StringName in district.rooms:
		if _room_district.has(room_id):
			push_error("World: la sala %s está en dos distritos (%s y %s)" % [room_id, _room_district[room_id], district.district_id])
			continue
		_room_district[room_id] = district.district_id
	districts[district.district_id] = district
