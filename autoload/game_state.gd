extends Node
## Estado de la partida: recursos de la institución, incidentes, pistas y decisiones.
## Está registrado como autoload "GameState" en project.godot.
## Todo lo que habría que guardar vive aquí: to_dict() / from_dict() preparan el guardado.

signal stats_changed
signal incident_state_changed(incident: Incident, state: Incident.State)
signal clue_found(incident: Incident, clue: Clue)
signal control_applied(incident: Incident, control: SecurityControl)

const STAT_MIN := 0
const STAT_MAX := 100

const START_BUDGET := 10000
const START_SECURITY := 35
const START_TRUST := 60

## Dinero disponible para implementar medidas de seguridad.
var budget := START_BUDGET
## Nivel general de protección de la institución (0-100).
var security := START_SECURITY
## Percepción de estudiantes, docentes y administrativos (0-100).
var trust := START_TRUST

var _incident_states: Dictionary[StringName, int] = {}
var _found_clues: Dictionary[StringName, bool] = {}
var _flags: Dictionary[StringName, bool] = {}
## Historial de decisiones: [{ "incident": "...", "control": "..." }]
var _decision_log: Array[Dictionary] = []


## Vuelve al estado inicial (nueva partida).
func reset() -> void:
	budget = START_BUDGET
	security = START_SECURITY
	trust = START_TRUST
	_incident_states.clear()
	_found_clues.clear()
	_flags.clear()
	_decision_log.clear()
	stats_changed.emit()


func can_afford(cost: int) -> bool:
	return budget >= cost


# --- Incidentes ---

func get_incident_state(incident: Incident) -> Incident.State:
	var state: int = _incident_states.get(incident.id, Incident.State.INACTIVE)
	return state as Incident.State


## Comienza la investigación (p. ej. cuando un NPC reporta el problema).
## Devuelve false si el incidente ya había comenzado.
func start_incident(incident: Incident) -> bool:
	if get_incident_state(incident) != Incident.State.INACTIVE:
		return false
	_set_incident_state(incident, Incident.State.INVESTIGATING)
	return true


## Registra una pista. Solo cuenta mientras se investiga el incidente.
## Devuelve true si la pista es nueva.
func find_clue(incident: Incident, clue: Clue) -> bool:
	var state := get_incident_state(incident)
	if state != Incident.State.INVESTIGATING and state != Incident.State.READY:
		return false
	if not incident.has_clue(clue) or has_clue(clue):
		return false
	_found_clues[clue.id] = true
	clue_found.emit(incident, clue)
	if state == Incident.State.INVESTIGATING and count_found_clues(incident) >= incident.clues_to_decide:
		_set_incident_state(incident, Incident.State.READY)
	return true


func has_clue(clue: Clue) -> bool:
	return _found_clues.has(clue.id)


func count_found_clues(incident: Incident) -> int:
	var count := 0
	for clue in incident.clues:
		if has_clue(clue):
			count += 1
	return count


## Indica si se puede aplicar la medida y, si no, por qué (texto para la interfaz).
func check_control(incident: Incident, control: SecurityControl) -> String:
	match get_incident_state(incident):
		Incident.State.RESOLVED:
			return "Este incidente ya fue resuelto."
		Incident.State.INACTIVE, Incident.State.INVESTIGATING:
			return "Aún no hay evidencia suficiente."
	if not incident.has_control(control):
		return "Esta medida no aplica a este incidente."
	if not can_afford(control.cost):
		return "Presupuesto insuficiente."
	return ""


## Aplica una medida: cobra el costo, modifica los indicadores y resuelve el incidente.
## Devuelve false (sin cambiar nada) si check_control() indica un problema.
func apply_control(incident: Incident, control: SecurityControl) -> bool:
	var problem := check_control(incident, control)
	if not problem.is_empty():
		push_warning("GameState: no se aplicó '%s': %s" % [control.id, problem])
		return false
	budget -= control.cost
	security = clampi(security + control.security_delta, STAT_MIN, STAT_MAX)
	trust = clampi(trust + control.trust_delta, STAT_MIN, STAT_MAX)
	for flag in control.flags_to_set:
		_flags[flag] = true
	_decision_log.append({ "incident": String(incident.id), "control": String(control.id) })
	stats_changed.emit()
	_set_incident_state(incident, Incident.State.RESOLVED)
	control_applied.emit(incident, control)
	return true


## Marcas dejadas por decisiones anteriores (consecuencias posteriores).
func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


func get_decision_log() -> Array[Dictionary]:
	return _decision_log.duplicate(true)


func _set_incident_state(incident: Incident, state: Incident.State) -> void:
	_incident_states[incident.id] = state
	incident_state_changed.emit(incident, state)


# --- Guardado (preparado para más adelante) ---

func to_dict() -> Dictionary:
	return {
		"budget": budget,
		"security": security,
		"trust": trust,
		"incident_states": _keys_to_strings(_incident_states),
		"found_clues": _key_list(_found_clues),
		"flags": _key_list(_flags),
		"decision_log": _decision_log.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	reset()
	budget = data.get("budget", START_BUDGET)
	security = data.get("security", START_SECURITY)
	trust = data.get("trust", START_TRUST)
	var states: Dictionary = data.get("incident_states", {})
	for incident_id: String in states:
		_incident_states[StringName(incident_id)] = int(states[incident_id])
	for clue_id: String in data.get("found_clues", []):
		_found_clues[StringName(clue_id)] = true
	for flag: String in data.get("flags", []):
		_flags[StringName(flag)] = true
	for entry: Dictionary in data.get("decision_log", []):
		_decision_log.append(entry)
	stats_changed.emit()


func _keys_to_strings(source: Dictionary) -> Dictionary:
	var result := {}
	for key: StringName in source:
		result[String(key)] = source[key]
	return result


func _key_list(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key: StringName in source:
		result.append(String(key))
	return result
