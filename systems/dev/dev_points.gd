class_name DevPoints
extends RefCounted
## Puntos de la historia para el menú de pruebas (DevMenu, F9, solo en el editor): cada uno deja la
## partida como si se hubiera jugado hasta ahí y abre la sala. Al agregar una parte nueva de la historia,
## se suma aquí (y test_menu_pruebas comprueba que todos funcionen).
##
## Campos de cada punto:
##   grupo, nombre       : cómo se muestra en el menú.
##   escena, entrada     : la sala y la entrada (vacía = el punto de inicio de la sala).
##   sala                : room_id del mapa (para World).
##   mision              : [misión, paso] al que se llega (se completa todo lo anterior en orden).
##   habilidades         : lo que dan las salas en el camino (vision, nullblade, inmersion, dominio).
##   marcas              : marcas extra (checkpoints de la persecución, jefes vencidos...).

## Las misiones de la historia, en orden (cada una empieza la siguiente al completarse).
const CHAIN: Array[StringName] = [&"prologo", &"contrasena_profesor", &"cuarto_viejo", &"una_clase_diferente",
	&"travesuras_en_el_sistema", &"camino_a_casa", &"el_lenguaje_de_las_maquinas", &"codigo_fuera_de_control"]

const Z := "res://world/zones/zone0/"
const RED := "res://world/zones/red_entrenamiento/"
const SIM := "res://world/zones/simulador/"
const BARRIO := "res://world/zones/barrio/"
const FIBRA := "res://world/zones/bosque_fibra/"

const POINTS: Array[Dictionary] = [
	{ "grupo": "Prólogo", "nombre": "Inicio del juego (la entrada)", "escena": Z + "entrada.tscn", "entrada": &"",
		"sala": &"entrada", "mision": [&"prologo", &"hablar_profesor"], "habilidades": [], "marcas": [] },
	{ "grupo": "Prólogo", "nombre": "El cuarto viejo (antes de la Nullblade)", "escena": Z + "pasillo_viejo.tscn",
		"entrada": &"desde_laboratorio", "sala": &"pasillo_viejo", "mision": [&"cuarto_viejo", &"ir_pasillo_viejo"],
		"habilidades": [&"vision"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Inicio del capítulo (sales del cuarto viejo)", "escena": Z + "pasillo_viejo.tscn",
		"entrada": &"desde_cuarto_viejo", "sala": &"pasillo_viejo", "mision": [&"una_clase_diferente", &"ir_a_clase"],
		"habilidades": [&"vision", &"nullblade"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "La clase en la Sala 3", "escena": Z + "sala_3.tscn", "entrada": &"desde_pasillo",
		"sala": &"sala_3", "mision": [&"una_clase_diferente", &"ir_a_clase"], "habilidades": [&"vision", &"nullblade"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Persecución corta (pasillo y escaleras)", "escena": Z + "pasillo.tscn",
		"entrada": &"desde_sala_3", "sala": &"pasillo", "mision": [&"una_clase_diferente", &"seguir_criaturas"],
		"habilidades": [&"vision", &"nullblade"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Persecución larga (pasillo del segundo piso)", "escena": Z + "pasillo_segundo.tscn",
		"entrada": &"desde_escaleras", "sala": &"pasillo_segundo", "mision": [&"una_clase_diferente", &"seguir_criaturas"],
		"habilidades": [&"vision", &"nullblade"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Biblioteca (el archivo privado)", "escena": Z + "biblioteca.tscn",
		"entrada": &"desde_escaleras", "sala": &"biblioteca", "mision": [&"una_clase_diferente", &"biblioteca"],
		"habilidades": [&"vision", &"nullblade"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "El patio y la soda (recreo)", "escena": Z + "patio.tscn", "entrada": &"desde_entrada",
		"sala": &"patio", "mision": [&"una_clase_diferente", &"pedir_permiso"], "habilidades": [&"vision", &"nullblade"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Tras las huellas del error (buscar rastros)", "escena": Z + "sala_3.tscn",
		"entrada": &"desde_pasillo", "sala": &"sala_3", "mision": [&"una_clase_diferente", &"buscar_huellas"],
		"habilidades": [&"vision", &"nullblade"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Cuarto técnico (servidor en rojo)", "escena": Z + "cuarto_tecnico.tscn",
		"entrada": &"desde_escaleras", "sala": &"cuarto_tecnico", "mision": [&"travesuras_en_el_sistema", &"revisar_servidor"],
		"habilidades": [&"vision", &"nullblade"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Persecución digital · tramo 1", "escena": RED + "persecucion.tscn", "entrada": &"inicio",
		"sala": &"persecucion", "mision": [&"travesuras_en_el_sistema", &"seguirlos_adentro"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Camino a casa · los amigos en la entrada", "escena": Z + "entrada.tscn",
		"entrada": &"desde_pasillo", "sala": &"entrada", "mision": [&"camino_a_casa", &"charla_amigos"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Camino a casa · la calle del barrio", "escena": BARRIO + "calle.tscn",
		"entrada": &"desde_colegio", "sala": &"calle", "mision": [&"camino_a_casa", &"volver_a_casa"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Casa de Kai · la charla familiar", "escena": BARRIO + "casa.tscn",
		"entrada": &"desde_calle", "sala": &"casa", "mision": [&"camino_a_casa", &"hablar_familia"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 1", "nombre": "Cuarto de Kai · la noche (descansar)", "escena": BARRIO + "cuarto_kai.tscn",
		"entrada": &"desde_casa", "sala": &"cuarto_kai", "mision": [&"camino_a_casa", &"descansar"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [&"cap1_charla_familiar"] },
	{ "grupo": "Capítulo 1", "nombre": "Persecución digital · tramo 2", "escena": RED + "persecucion.tscn", "entrada": &"checkpoint_1",
		"sala": &"persecucion", "mision": [&"travesuras_en_el_sistema", &"persecucion"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [&"cap1_checkpoint_1"] },
	{ "grupo": "Capítulo 1", "nombre": "Persecución digital · tramo 3", "escena": RED + "persecucion.tscn", "entrada": &"checkpoint_2",
		"sala": &"persecucion", "mision": [&"travesuras_en_el_sistema", &"persecucion"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [&"cap1_checkpoint_1", &"cap1_checkpoint_2"] },
	{ "grupo": "Capítulo 1", "nombre": "Jefe: Glitch y Chip", "escena": RED + "arena_hermanos.tscn", "entrada": &"desde_persecucion",
		"sala": &"arena_hermanos", "mision": [&"travesuras_en_el_sistema", &"vencer_hermanos"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"],
		"marcas": [&"cap1_checkpoint_1", &"cap1_checkpoint_2", &"cap1_checkpoint_3"] },
	{ "grupo": "Capítulo 1", "nombre": "Final (GENESIS_ARCHIVE)", "escena": Z + "cuarto_tecnico.tscn", "entrada": &"desde_red",
		"sala": &"cuarto_tecnico", "mision": [&"travesuras_en_el_sistema", &"hablar_profesor"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"],
		"marcas": [&"cap1_checkpoint_1", &"cap1_checkpoint_2", &"cap1_checkpoint_3", &"cap1_hermanos_vencidos", &"cap1_fragmento_leido"] },
	{ "grupo": "Capítulo 2", "nombre": "Inicio del capítulo (la entrada del colegio)", "escena": Z + "entrada.tscn",
		"entrada": &"desde_pasillo", "sala": &"entrada", "mision": [&"el_lenguaje_de_las_maquinas", &"clase_programacion"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Clase de programación (Sala 3)", "escena": Z + "sala_3.tscn", "entrada": &"desde_pasillo",
		"sala": &"sala_3", "mision": [&"el_lenguaje_de_las_maquinas", &"clase_programacion"], "habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Taller de robótica (las tres estaciones)", "escena": Z + "taller.tscn",
		"entrada": &"desde_laboratorio", "sala": &"taller", "mision": [&"el_lenguaje_de_las_maquinas", &"taller_robotica"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Taller: las anomalías (con la Visión)", "escena": Z + "taller.tscn",
		"entrada": &"desde_laboratorio", "sala": &"taller", "mision": [&"el_lenguaje_de_las_maquinas", &"investigar_anomalias"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [&"robotica_clasificador", &"robotica_cinta", &"robotica_asistente"] },
	{ "grupo": "Capítulo 2", "nombre": "Laboratorio: la conexión al simulador", "escena": Z + "laboratorio.tscn",
		"entrada": &"desde_pasillo", "sala": &"laboratorio", "mision": [&"el_lenguaje_de_las_maquinas", &"entrar_simulador"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Simulador · variables", "escena": SIM + "sim_variables.tscn", "entrada": &"desde_oeste",
		"sala": &"sim_variables", "mision": [&"el_lenguaje_de_las_maquinas", &"variables"], "habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Simulador · condiciones", "escena": SIM + "sim_condiciones.tscn", "entrada": &"desde_oeste",
		"sala": &"sim_condiciones", "mision": [&"el_lenguaje_de_las_maquinas", &"condiciones"], "habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Simulador · ciclos y repaso", "escena": SIM + "sim_ciclos.tscn", "entrada": &"desde_oeste",
		"sala": &"sim_ciclos", "mision": [&"el_lenguaje_de_las_maquinas", &"ciclos"], "habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Procesos repetidos", "escena": SIM + "sim_procesos.tscn", "entrada": &"desde_oeste",
		"sala": &"sim_procesos", "mision": [&"codigo_fuera_de_control", &"procesos"], "habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Jefe: Bucle Infinito", "escena": SIM + "arena_bucle.tscn", "entrada": &"inicio",
		"sala": &"arena_bucle", "mision": [&"codigo_fuera_de_control", &"vencer_bucle"], "habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [] },
	{ "grupo": "Capítulo 2", "nombre": "Final del capítulo (el profesor)", "escena": Z + "laboratorio.tscn",
		"entrada": &"desde_simulador", "sala": &"laboratorio", "mision": [&"codigo_fuera_de_control", &"hablar_profesor"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"],
		"marcas": [&"cap2_bucle_vencido", &"cap2_bucle_liberado", &"cap2_condicion_corregida", &"cap2_anomalia_vista", &"cap2_simulador_terminado"] },
	{ "grupo": "Mundo (Capítulo 3)", "nombre": "Sin señal en el barrio · la caja de fibra", "escena": BARRIO + "calle.tscn",
		"entrada": &"desde_casa", "sala": &"calle", "mision": [], "habilidades": [&"vision", &"nullblade", &"inmersion"],
		"marcas": [&"capitulo_3"] },
	{ "grupo": "Mundo (Capítulo 3)", "nombre": "Bosque de Fibra · raíces (seguir al Fibroluz)", "escena": FIBRA + "fibra_raices.tscn",
		"entrada": &"desde_barrio", "sala": &"fibra_raices", "mision": [&"senal_del_barrio", &"seguir_fibroluz"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [&"capitulo_3"] },
	{ "grupo": "Mundo (Capítulo 3)", "nombre": "Bosque de Fibra · el claro (reconectar)", "escena": FIBRA + "fibra_claro.tscn",
		"entrada": &"desde_raices", "sala": &"fibra_claro", "mision": [&"senal_del_barrio", &"reconectar"],
		"habilidades": [&"vision", &"nullblade", &"inmersion"], "marcas": [&"capitulo_3"] },
]


## Deja GameState como si se hubiera jugado hasta el punto (sin tocar las ranuras de guardado).
static func prepare(point: Dictionary, state: Node) -> void:
	state.reset()
	state.set_flag(&"menu_pruebas")
	var target: Array = point.get("mision", [])
	if target.is_empty():
		# Más allá de la historia armada: todas las misiones terminadas.
		_advance(state, &"", &"")
	else:
		_advance(state, target[0], target[1])
	var abilities: Array = point.get("habilidades", [])
	if abilities.has(&"vision"):
		state.unlock_vision()
	if abilities.has(&"nullblade"):
		state.set_nullblade_stage(maxi(state.nullblade_stage, 1))
		state.set_dash_level(maxi(state.dash_level, 1))
		state.set_flag(GameState.GRIMORIO_FLAG)
	if abilities.has(&"inmersion"):
		state.unlock_immersion()
	if abilities.has(&"dominio"):
		state.set_domain_stage(maxi(state.domain_stage, 1))
	for flag in point.get("marcas", []):
		state.set_flag(flag)


## Completa en orden las misiones de la historia hasta que la actual sea quest_id en step_id (con los dos
## vacíos, todas). Si quest_id es una actividad (no está en CHAIN), termina toda la historia armada y avanza esa
## actividad hasta el paso.
static func _advance(state: Node, quest_id: StringName, step_id: StringName) -> void:
	if quest_id != &"" and not CHAIN.has(quest_id):
		_advance(state, &"", &"")
		state.start_quest(quest_id)
		for step in QuestDB.get_quest(quest_id).steps:
			if step.id == step_id:
				return
			state.complete_step(quest_id, step.id)
		return
	state.start_quest(CHAIN[0])
	for chain_quest in CHAIN:
		if chain_quest == quest_id and state.get_current_step(chain_quest) == step_id:
			return
		var quest := QuestDB.get_quest(chain_quest)
		for step in quest.steps:
			if chain_quest == quest_id and step.id == step_id:
				return
			state.complete_step(chain_quest, step.id)
