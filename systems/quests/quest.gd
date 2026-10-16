class_name Quest
extends Resource
## Misión: una lista de pasos en orden. Los eventos del mundo (diálogos, computadoras, combates)
## completan los pasos con GameState.complete_step(id_mision, id_paso).
## Se edita en el Inspector; cada misión nueva se registra en QuestDB.

## Principal (la historia), secundaria (historia opcional), tarea (encargo breve), descubrimiento (lugar,
## documento o ruta oculta) o especial (una parte de la historia con nombre propio dentro de un nivel, p. ej. «Eco en
## la Red»). Ver docs/misiones/SISTEMA_DE_MISIONES.md.
enum Category { PRINCIPAL, SECUNDARIA, TAREA, DESCUBRIMIENTO, ESPECIAL }

const CATEGORY_NAMES: Array[String] = ["Misión principal", "Misión secundaria", "Tarea", "Descubrimiento", "Misión especial"]

@export var id: StringName = &""
@export var title := ""
@export var category := Category.PRINCIPAL
## Capítulo al que pertenece (0 = sin capítulo). Las secundarias y tareas de un capítulo tienen que estar terminadas
## para empezar el Capítulo 3 (ChapterGate): son de antes de que Kai conozca a Aegis.
@export var chapter := 0
@export var steps: Array[QuestStep] = []
## Título grande que aparece al completarla (p. ej. "EL DESPERTAR"). Vacío = ninguno.
@export var completion_title := ""
@export var completion_subtitle := ""
## Título que aparece después del de completar (p. ej. el capítulo que empieza). Vacío = ninguno.
@export var followup_title := ""
@export var followup_subtitle := ""
## Marca que queda en GameState al completarla (p. ej. &"tutorial_terminado").
@export var completion_flag: StringName = &""
## Más marcas al completarla (p. ej. el nivel y el capítulo).
@export var extra_completion_flags: Array[StringName] = []
## Marca que queda al empezarla (p. ej. &"capitulo_2": abre las salas de ese capítulo).
@export var start_flag: StringName = &""
## Misión que empieza automáticamente al completar esta (vacío = ninguna).
@export var next_quest: StringName = &""
## Ecos que se reciben al completarla (0 = ninguno).
@export var ecos_reward := 0


func get_step_index(step_id: StringName) -> int:
	for i in steps.size():
		if steps[i].id == step_id:
			return i
	return -1
