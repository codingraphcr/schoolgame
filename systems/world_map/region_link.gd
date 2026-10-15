class_name RegionLink
extends Resource
## Una conexión entre dos regiones (bidireccional salvo one_way): un camino, una conexión de Inmersión
## Digital (siempre desde un dispositivo concreto: access_point), un atajo, un pasaje oculto o una
## conexión vertical. Se puede usar cuando se cumple requirement (vacío = siempre). Los pasajes ocultos no
## se dibujan hasta que se cumple su requisito. Registro: WorldAtlas.

enum Kind { CAMINO, INMERSION, ATAJO, OCULTO, VERTICAL }

const KIND_NAMES: Array[String] = ["Camino", "Inmersión Digital", "Atajo", "Pasaje oculto", "Conexión vertical"]

@export var id: StringName = &""
@export var region_a: StringName = &""
@export var region_b: StringName = &""
@export var kind := Kind.CAMINO
@export var one_way := false
## Qué es en el mundo (el dispositivo o lugar): «Caja de fibra óptica del poste de la calle de Kai».
@export var access_point := ""
## Para qué existe (qué sistema conecta y por qué).
@export_multiline var purpose := ""
@export var requirement: WorldRequirement


func is_open(state: Node) -> bool:
	return requirement == null or requirement.is_met(state)


func locked_text() -> String:
	return requirement.locked_text if requirement and not requirement.locked_text.is_empty() else "Todavía no se puede pasar."


func touches(region_id: StringName) -> bool:
	return region_a == region_id or region_b == region_id


func other(region_id: StringName) -> StringName:
	return region_b if region_a == region_id else region_a
