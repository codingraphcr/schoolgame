class_name ComputerEntry
extends Resource
## Algo que se lee en la computadora del cuarto de Kai (KaiComputerWindow): un mensaje de un amigo, un
## proyecto del colegio o una nota personal. Aparece cuando la partida llegó a min_chapter y tiene
## requires_flag (vacía = no pide ninguna); con hidden_flag deja de aparecer (p. ej. un mensaje viejo).
## Es contenido del juego: no hay internet ni archivos reales.

enum Section { MENSAJES, PROYECTOS, NOTAS }

const SECTION_NAMES: Array[String] = ["Mensajes", "Proyectos", "Notas"]

const PATHS: Array[String] = [
	"res://data/home/computadora/mensaje_laboratorio.tres",
	"res://data/home/computadora/mensaje_companera.tres",
	"res://data/home/computadora/proyecto_redes.tres",
	"res://data/home/computadora/proyecto_robot.tres",
	"res://data/home/computadora/nota_cosas_raras.tres",
	"res://data/home/computadora/nota_resonancia.tres",
]

@export var section := Section.MENSAJES
@export var title := ""
## Quién lo manda (mensajes) o de qué materia es (proyectos).
@export var from := ""
@export_multiline var body := ""
@export var min_chapter := 0
@export var requires_flag: StringName = &""
@export var hidden_flag: StringName = &""


func is_visible_for(state: Node) -> bool:
	if ProgressTracker.chapter(state) < min_chapter:
		return false
	if requires_flag != &"" and not state.has_flag(requires_flag):
		return false
	return hidden_flag == &"" or not state.has_flag(hidden_flag)


static func visible_in(section_id: Section, state: Node) -> Array[ComputerEntry]:
	var result: Array[ComputerEntry] = []
	for path in PATHS:
		var entry := load(path) as ComputerEntry
		if entry and entry.section == section_id and entry.is_visible_for(state):
			result.append(entry)
	return result
