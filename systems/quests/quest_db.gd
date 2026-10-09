class_name QuestDB
extends RefCounted
## Registro de las misiones del juego (id → archivo). Para agregar una misión: crear el .tres en
## data/quests/ y añadirla aquí.

const PATHS := {
	&"prologo": "res://data/quests/prologo.tres",
	&"contrasena_profesor": "res://data/quests/contrasena_profesor.tres",
}


static func get_quest(quest_id: StringName) -> Quest:
	if not PATHS.has(quest_id):
		return null
	return load(PATHS[quest_id]) as Quest
