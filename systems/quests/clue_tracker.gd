class_name ClueTracker
extends RefCounted
## Cuenta marcas de un grupo (rastros, anomalías, estaciones...) y completa un paso de misión cuando se juntan las
## necesarias. Lo comparten ErrorTrace, Anomaly y RoboticsStation para no repetir la misma lógica.


static func count(state: Node, flags: Array[StringName]) -> int:
	var found := 0
	for flag in flags:
		if state.has_flag(flag):
			found += 1
	return found


## Deja flag y, si ya hay required marcas del grupo y la misión está en step, completa ese paso.
static func register(state: Node, flag: StringName, flags: Array[StringName], required: int, quest: StringName, step: StringName) -> void:
	state.set_flag(flag)
	if count(state, flags) >= required and state.get_current_step(quest) == step:
		state.complete_step(quest, step)
