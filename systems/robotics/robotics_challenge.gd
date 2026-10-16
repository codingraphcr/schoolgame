class_name RoboticsChallenge
extends Resource
## Una estación de la actividad de robótica del taller (Capítulo 2). Las tres estaciones usan la misma ventana
## (RoboticsWindow): el jugador arma un programa corto eligiendo una opción en cada casilla (slots), lo ejecuta y
## mira en la simulación qué pasa. Qué hace cada estación lo decide su simulación (RoboticsSim, según kind).
## Nunca se ejecuta código real: todo es una simulación controlada (un ciclo sin salida se detiene solo).
## Un .tres por estación en data/robotics/.

enum Kind { CONDICIONAL, CICLO, FUNCION, SECUENCIA }

## Id estable (para la marca «robotica_<id>», la recompensa y el guardado).
@export var id: StringName = &""
@export var kind := Kind.CONDICIONAL
@export var title := ""
## El proyecto y lo que tiene que lograr el programa (se muestra arriba).
@export_multiline var goal := ""
## Las casillas del programa, en orden (las opciones de cada una las define la simulación).
@export var slots: Array[RoboticsSlot] = []
## Pistas, de la más general a la más concreta (se muestran de una en una).
@export var hints: PackedStringArray = []
## Lo que se aprendió (al resolverla).
@export_multiline var success_text := ""
## Ecos al resolverla por primera vez (-1 = sorteado entre los de desafío en EconomyConfig).
@export var ecos_reward := -1


## La simulación de esta estación.
func create_sim() -> RoboticsSim:
	match kind:
		Kind.CICLO:
			return ConveyorSim.new()
		Kind.FUNCION:
			return AssistantSim.new()
		Kind.SECUENCIA:
			return SequenceSim.new()
	return SorterSim.new()


## Si una elección de opciones (una por casilla) resuelve la estación.
func solves(choices: Array[int]) -> bool:
	return create_sim().run(choices).ok
