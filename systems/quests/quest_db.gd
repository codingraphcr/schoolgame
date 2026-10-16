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
	# Entre el Capítulo 1 y el 2: la vuelta a casa (docs/escenarios/HOGAR_DE_KAI.md).
	&"camino_a_casa": "res://data/quests/camino_a_casa.tres",
	# Capítulo 2.
	&"el_lenguaje_de_las_maquinas": "res://data/quests/el_lenguaje_de_las_maquinas.tres",
	&"codigo_fuera_de_control": "res://data/quests/codigo_fuera_de_control.tres",
	# Actividades del mundo (docs/misiones/MISIONES_SECUNDARIAS.md).
	&"senal_del_barrio": "res://data/quests/senal_del_barrio.tres",
	&"foto_antigua": "res://data/quests/foto_antigua.tres",
	&"un_recreo_diferente": "res://data/quests/un_recreo_diferente.tres",
	&"proyecto_perdido": "res://data/quests/proyecto_perdido.tres",
}


static func get_quest(quest_id: StringName) -> Quest:
	if not PATHS.has(quest_id):
		return null
	return load(PATHS[quest_id]) as Quest
