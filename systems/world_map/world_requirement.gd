class_name WorldRequirement
extends Resource
## Lo que pide algo del mundo para estar disponible (una conexión entre regiones, un acceso, una región que
## se deja ver): capítulo mínimo, marcas de GameState, misiones terminadas y habilidades. Todo se lee de la
## partida (ranura activa): nada se guarda aquí. Vacío = siempre.
##
## Habilidades que se pueden pedir: "vision", "inmersion", "dominio", "aegis_pulse", "aegis_bridge",
## "aegis_sync", "salto_de_nexo", "doble_salto", "dash".

@export var min_chapter := 0
@export var flags: PackedStringArray = []
@export var quests_completed: PackedStringArray = []
@export var abilities: PackedStringArray = []
## Lo que se le dice al jugador mientras no se cumple (p. ej. «Se abre en el Capítulo 3»).
@export var locked_text := ""


func is_met(state: Node) -> bool:
	if ProgressTracker.chapter(state) < min_chapter:
		return false
	for flag in flags:
		if not state.has_flag(StringName(flag)):
			return false
	for quest in quests_completed:
		if not state.is_quest_completed(StringName(quest)):
			return false
	for ability in abilities:
		if not has_ability(state, ability):
			return false
	return true


static func has_ability(state: Node, ability: String) -> bool:
	match ability:
		"vision":
			return state.vision_unlocked
		"inmersion":
			return state.immersion_unlocked
		"dominio":
			return state.domain_stage >= 1
		"aegis_pulse":
			return state.aegis_stage >= 1
		"aegis_bridge":
			return state.aegis_stage >= 2
		"aegis_sync":
			return state.aegis_stage >= 3
		"salto_de_nexo":
			return state.has_flag(&"salto_de_nexo")
		"doble_salto":
			return state.can_double_jump
		"dash":
			return state.dash_level >= 1
	push_warning("WorldRequirement: habilidad desconocida «%s»" % ability)
	return false
