class_name QuestDB
extends RefCounted
## Registro de las misiones del juego (id → archivo). Para agregar una misión: crear el .tres en
## data/quests/ y añadirla aquí.

const PATHS := {
	&"prologo": "res://data/quests/prologo.tres",
	&"contrasena_profesor": "res://data/quests/contrasena_profesor.tres",
	&"cuarto_viejo": "res://data/quests/cuarto_viejo.tres",
	# Capítulo 1 (todavía no empieza sola: se encadena cuando el nivel se pueda jugar).
	&"una_clase_diferente": "res://data/quests/una_clase_diferente.tres",
	&"travesuras_en_el_sistema": "res://data/quests/travesuras_en_el_sistema.tres",
}


static func get_quest(quest_id: StringName) -> Quest:
	if not PATHS.has(quest_id):
		return null
	return load(PATHS[quest_id]) as Quest
