class_name Quest
extends Resource
## Misión: una lista de pasos en orden. Los eventos del mundo (diálogos, computadoras, combates)
## completan los pasos con GameState.complete_step(id_mision, id_paso).
## Se edita en el Inspector; cada misión nueva se registra en QuestDB.

@export var id: StringName = &""
@export var title := ""
@export var steps: Array[QuestStep] = []
## Título grande que aparece al completarla (p. ej. "EL DESPERTAR"). Vacío = ninguno.
@export var completion_title := ""
@export var completion_subtitle := ""
## Misión que empieza automáticamente al completar esta (vacío = ninguna).
@export var next_quest: StringName = &""


func get_step_index(step_id: StringName) -> int:
	for i in steps.size():
		if steps[i].id == step_id:
			return i
	return -1
