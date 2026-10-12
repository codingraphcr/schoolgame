class_name RoomTemplate
extends Resource
## Ficha de una sala del mundo (una escena de Godot reutilizable): datos de navegación separados
## del dibujo. El generador del mapa y el Grimorio usan estas fichas. Una por sala en
## data/world/rooms/ (RoomTemplateDB las carga).

@export var id: StringName = &""
@export var display_name := ""
@export_file("*.tscn") var scene_path := ""
## street, corridor, classroom, laboratory, library, stairs, elevator, rooftop, basement,
## technical_room, storage, secret_room…
@export var room_type: StringName = &"corridor"
@export var district_id: StringName = &"colegio"
## Tamaño en celdas de la cuadrícula del mapa.
@export var size_cells := Vector2i.ONE
@export var doors: Array[DoorSpec] = []

@export_group("Generación")
## Sala obligatoria de posición fija (no la mueve el generador).
@export var fixed := false
@export var secret_room := false
## Probabilidad relativa de aparecer entre las opcionales compatibles.
@export var generation_weight := 1.0
@export_range(0, 5) var difficulty := 0
## Habilidades necesarias para recorrerla (p. ej. &"double_jump").
@export var minimum_player_abilities: PackedStringArray = []
## Capítulo desde el que puede aparecer (0 = prólogo).
@export var chapter_requirement := 0
@export var allowed_enemy_types: PackedStringArray = []

@export_group("Contenido")
@export var educational_objectives: PackedStringArray = []
@export var mission_ids: PackedStringArray = []


func door(door_id: StringName) -> DoorSpec:
	for spec in doors:
		if spec.id == door_id:
			return spec
	return null


## Celdas que ocupa la sala colocada en esa posición.
func cells_at(origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in size_cells.y:
		for x in size_cells.x:
			result.append(origin + Vector2i(x, y))
	return result


## Errores de la ficha (vacío si está bien). Lo usan las pruebas y, más adelante, el generador.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id == &"":
		errors.append("sala sin id")
	if size_cells.x < 1 or size_cells.y < 1:
		errors.append("%s: tamaño en celdas inválido %s" % [id, size_cells])
	if not scene_path.is_empty() and not ResourceLoader.exists(scene_path):
		errors.append("%s: no existe la escena %s" % [id, scene_path])
	var seen: Dictionary[StringName, bool] = {}
	for spec in doors:
		if spec == null:
			errors.append("%s: puerta vacía" % id)
			continue
		if spec.id == &"" or seen.has(spec.id):
			errors.append("%s: puerta sin id o repetida (%s)" % [id, spec.id])
		seen[spec.id] = true
		if spec.cell.x < 0 or spec.cell.y < 0 or spec.cell.x >= size_cells.x or spec.cell.y >= size_cells.y:
			errors.append("%s.%s: la celda %s está fuera de la sala" % [id, spec.id, spec.cell])
			continue
		# La puerta tiene que estar en el borde de la sala que da a su lado.
		var outside := spec.cell + DoorSpec.step(spec.side)
		if outside.x >= 0 and outside.y >= 0 and outside.x < size_cells.x and outside.y < size_cells.y:
			errors.append("%s.%s: no está en el borde de la sala" % [id, spec.id])
		var vertical_side := spec.side in [DoorSpec.Side.UP, DoorSpec.Side.DOWN]
		if DoorSpec.is_vertical(spec.kind) and not vertical_side:
			errors.append("%s.%s: una escalera o un ascensor va arriba o abajo" % [id, spec.id])
		if spec.kind == DoorSpec.Kind.DOOR and vertical_side:
			errors.append("%s.%s: una puerta va a la izquierda o a la derecha" % [id, spec.id])
	return errors


## Todas las fichas de una carpeta, por id (funciona también en el juego exportado).
static func load_folder(folder := "res://data/world/rooms") -> Dictionary[StringName, RoomTemplate]:
	var result: Dictionary[StringName, RoomTemplate] = {}
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	for file: String in files:
		if not file.ends_with(".tres"):
			continue
		var template := load(folder.path_join(file)) as RoomTemplate
		if template:
			result[template.id] = template
	return result
