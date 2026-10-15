class_name Bestiary
extends RefCounted
## El bestiario del Grimorio: qué sabe Kai de cada criatura digital (CreatureEntry). La etapa vive en las
## marcas de la partida («bestiario_<id>_<etapa>»): va en la ranura y no se mezcla entre partidas. Solo
## se registran las criaturas que existen en el juego (ENTRIES).

const STAGE_NAMES: Array[String] = ["Sin registro", "Avistamiento", "Observación", "Comprensión"]

const ENTRIES: Array[String] = [
	"res://data/bestiary/fibroluz.tres",
]


static func entries() -> Array[CreatureEntry]:
	var result: Array[CreatureEntry] = []
	for path in ENTRIES:
		var entry := load(path) as CreatureEntry
		if entry:
			result.append(entry)
	return result


static func get_entry(id: StringName) -> CreatureEntry:
	for entry in entries():
		if entry.id == id:
			return entry
	return null


## Etapa conocida (0 = nunca la vio; 3 = la comprende). La comprensión también llega con understand_flag.
static func stage(state: Node, entry: CreatureEntry) -> int:
	if entry.understand_flag != &"" and state.has_flag(entry.understand_flag):
		return 3
	for n in range(3, 0, -1):
		if state.has_flag(_flag(entry.id, n)):
			return n
	return 0


## Sube a esa etapa si es nueva (nunca baja). true si avanzó (para avisar).
static func advance(state: Node, entry: CreatureEntry, new_stage: int) -> bool:
	if stage(state, entry) >= new_stage:
		return false
	for n in range(1, new_stage + 1):
		state.set_flag(_flag(entry.id, n))
	return true


static func _flag(id: StringName, n: int) -> StringName:
	return StringName("bestiario_%s_%d" % [id, n])
