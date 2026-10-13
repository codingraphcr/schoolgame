extends Node
## El mapa del mundo: los grafos de los distritos (RoomGraph) y en qué sala está Kai.
##
## Cada distrito parte de su parte fija (DistrictLayout en data/world/districts/) y el generador
## (DistrictGenerator, M4) le cuelga salas opcionales según world_seed: misma semilla, mismo mapa.
##
## Lo que se guarda en la partida (to_dict / from_dict): la semilla, la versión del generador y las
## salas visitadas. Política: los distritos fijos se arman siempre desde los datos actuales (así una
## actualización puede sumar salas); lo procedural se arma con la semilla y la versión del generador
## guardadas, para que una partida existente no cambie de mapa al actualizar el juego.
##
## Las salas (Room) avisan al entrar con enter(); las salidas (RoomExit) preguntan a dónde lleva su
## puerta con destination(). Si una sala o una puerta no está en el mapa, siguen funcionando como
## antes (con su target_scene).
##
## Uso: World.current_room · World.destination(&"entrada", &"este") · World.room_entered

signal room_entered(room_id: StringName, district_id: StringName)

const ROOMS_FOLDER := "res://data/world/rooms"
const DISTRICTS_FOLDER := "res://data/world/districts"
## Versión del generador del mapa. Si cambia el algoritmo, sube; las partidas guardan la suya.
const GENERATOR_VERSION := DistrictGenerator.VERSION

var templates: Dictionary[StringName, RoomTemplate] = {}
## district_id → RoomGraph
var districts: Dictionary[StringName, RoomGraph] = {}
var current_room: StringName = &""
var current_district: StringName = &""
## Semilla del mapa de esta partida (la usa el generador).
var world_seed := 0
## Versión del generador con la que se creó el mapa de esta partida.
var generator_version := GENERATOR_VERSION
## Salas donde estuvo Kai en esta partida.
var visited: Dictionary[StringName, bool] = {}
## district_id → nombre para mostrar (del DistrictLayout).
var district_names: Dictionary[StringName, String] = {}

## room_id → district_id
var _room_district: Dictionary[StringName, StringName] = {}


func _ready() -> void:
	reset()


## Vuelve a armar el mapa desde los datos, con la semilla actual.
func reset() -> void:
	templates = RoomTemplate.load_folder(ROOMS_FOLDER)
	districts.clear()
	district_names.clear()
	_room_district.clear()
	current_room = &""
	current_district = &""
	var files := Array(ResourceLoader.list_directory(DISTRICTS_FOLDER))
	files.sort()
	for file: String in files:
		var layout := load(DISTRICTS_FOLDER.path_join(file)) as DistrictLayout if file.ends_with(".tres") else null
		if layout == null:
			continue
		var graph := DistrictGenerator.new().generate(layout, templates, world_seed)
		if graph:
			_add_district(graph)
			district_names[layout.id] = layout.display_name


## Mapa de una partida nueva: otra semilla y ninguna sala visitada.
func new_world(seed_value := -1) -> void:
	world_seed = seed_value if seed_value >= 0 else int(Crypto.new().generate_random_bytes(4).decode_u32(0) & 0x7fffffff)
	generator_version = GENERATOR_VERSION
	reset()
	visited.clear()


## Lo que se guarda del mapa. La semilla va como texto (el JSON de Godot pierde precisión en
## números grandes).
func to_dict() -> Dictionary:
	var rooms: Array[String] = []
	for room_id: StringName in visited:
		rooms.append(String(room_id))
	rooms.sort()
	return { "generador": generator_version, "semilla": str(world_seed), "visitadas": rooms }


## Restaura el mapa de una partida guardada. Sin datos (partidas viejas), crea una semilla nueva.
func from_dict(data: Dictionary) -> void:
	var seed_text := String(data.get("semilla", ""))
	if seed_text.is_valid_int():
		world_seed = int(seed_text)
		generator_version = int(data.get("generador", GENERATOR_VERSION))
		reset()
	else:
		new_world()
	visited.clear()
	for room_id: Variant in data.get("visitadas", []):
		if typeof(room_id) == TYPE_STRING and _room_district.has(StringName(room_id)):
			visited[StringName(room_id)] = true


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
		visited[room_id] = true
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


## Por qué todavía no se puede entrar a una sala ("" = se puede). El mapa se abre por capítulos:
## una sala con chapter_requirement N se abre al llegar al capítulo N (ProgressTracker.chapter()).
func lock_reason(room_id: StringName) -> String:
	var template := template_of(room_id)
	if template == null or template.chapter_requirement <= 0:
		return ""
	if ProgressTracker.chapter(get_node("/root/GameState")) >= template.chapter_requirement:
		return ""
	return "Por ahora no se puede pasar por aquí. (Se abre en el Capítulo %d)" % template.chapter_requirement


func _add_district(district: RoomGraph) -> void:
	for room_id: StringName in district.rooms:
		if _room_district.has(room_id):
			push_error("World: la sala %s está en dos distritos (%s y %s)" % [room_id, _room_district[room_id], district.district_id])
			continue
		_room_district[room_id] = district.district_id
	districts[district.district_id] = district
