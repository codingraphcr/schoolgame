extends Node
## Estado de la partida: recursos de la institución, incidentes, pistas y decisiones,
## y el progreso del jugador (créditos, habilidades y evoluciones de combate).
## Está registrado como autoload "GameState" en project.godot.
## Todo lo que habría que guardar vive aquí: to_dict() / from_dict() preparan el guardado.

signal stats_changed
signal incident_state_changed(incident: Incident, state: Incident.State)
signal clue_found(incident: Incident, clue: Clue)
signal control_applied(incident: Incident, control: SecurityControl)
## Cambió el progreso del jugador (créditos, habilidades o evoluciones).
signal progress_changed
## Cambiaron los créditos; delta es la diferencia (negativa al gastar o perder).
signal credits_changed(credits: int, delta: int)
signal quest_started(quest_id: StringName)
signal quest_step_changed(quest_id: StringName)
signal quest_completed(quest_id: StringName)

const STAT_MIN := 0
const STAT_MAX := 100

const START_BUDGET := 10000
const START_SECURITY := 35
const START_TRUST := 60

const START_MASKS := 4
const MAX_DASH_LEVEL := 3
const MAX_NULLBLADE_STAGE := 4
const MAX_AEGIS_STAGE := 3
const MAX_DOMAIN_STAGE := 3
## Fracción de los créditos que se pierde al morir.
const DEATH_CREDIT_PENALTY := 0.1

## Nombres para la interfaz. El índice es la etapa (0 = no obtenido).
const NULLBLADE_NAMES: Array[String] = ["—", "Nullblade.exe", "Nullblade.zero", "Nullblade.void", "Nullblade.max"]
const AEGIS_NAMES: Array[String] = ["—", "Aegis Pulse", "Aegis Bridge", "Aegis Sync"]
const DOMAIN_NAMES: Array[String] = ["—", "Dominio Nulo I", "Dominio Nulo II", "Dominio Nulo III"]
const DASH_NAMES: Array[String] = ["—", "Dash", "Dash Fantasma", "Esquiva Perfecta"]

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

# --- Progreso del jugador ---
# Separado del presupuesto del colegio: los créditos son del jugador y pagan sus mejoras.
# Solo se modifica con las funciones de abajo, que limitan los valores y avisan del cambio.

## Créditos del jugador (mejoras de habilidades). Se pierde una parte al morir.
var credits := 0
var max_masks := START_MASKS
## Máscaras actuales al salir de una sala (-1 = llenas). Así cambiar de sala no cura.
var current_masks := -1.0
## 0 = sin dash · 1 Dash · 2 Dash Fantasma · 3 Esquiva Perfecta.
var dash_level := 0
var can_double_jump := false
var can_wall_jump := false
var vision_unlocked := false
## 0 = no obtenida · 1 .exe · 2 .zero · 3 .void · 4 .max
var nullblade_stage := 0
## 0 = no obtenido · 1 Pulse · 2 Bridge · 3 Sync
var aegis_stage := 0
## 0 = bloqueado · 1, 2, 3 = versiones I, II, III
var domain_stage := 0

# --- Misiones ---
## Misión que se muestra como OBJETIVO (vacío = ninguna).
var active_quest: StringName = &""
## Paso actual de cada misión empezada (índice); -1 = completada.
var _quest_progress: Dictionary[StringName, int] = {}


## Vuelve al estado inicial (nueva partida).
func reset() -> void:
	budget = START_BUDGET
	security = START_SECURITY
	trust = START_TRUST
	_incident_states.clear()
	_found_clues.clear()
	_flags.clear()
	_decision_log.clear()
	_reset_progress()
	active_quest = &""
	_quest_progress.clear()
	stats_changed.emit()
	progress_changed.emit()


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


## Deja una marca (decisiones, eventos de la historia, objetos ya recogidos). Se guarda con la partida.
func set_flag(flag: StringName) -> void:
	_flags[flag] = true


func get_decision_log() -> Array[Dictionary]:
	return _decision_log.duplicate(true)


func _set_incident_state(incident: Incident, state: Incident.State) -> void:
	_incident_states[incident.id] = state
	incident_state_changed.emit(incident, state)


# --- Progreso del jugador ---

func add_credits(amount: int) -> void:
	if amount <= 0:
		return
	credits += amount
	credits_changed.emit(credits, amount)
	progress_changed.emit()


## Paga una mejora. Devuelve false (sin cobrar nada) si no alcanza.
func spend_credits(amount: int) -> bool:
	if amount < 0 or amount > credits:
		return false
	if amount > 0:
		credits -= amount
		credits_changed.emit(credits, -amount)
		progress_changed.emit()
	return true


## Al morir se pierde una parte de los créditos. Devuelve cuántos se perdieron.
func apply_death_penalty() -> int:
	var lost := floori(credits * DEATH_CREDIT_PENALTY)
	if lost > 0:
		credits -= lost
		credits_changed.emit(credits, -lost)
		progress_changed.emit()
	return lost


func set_dash_level(level: int) -> void:
	dash_level = clampi(level, 0, MAX_DASH_LEVEL)
	progress_changed.emit()


func set_nullblade_stage(stage: int) -> void:
	nullblade_stage = clampi(stage, 0, MAX_NULLBLADE_STAGE)
	progress_changed.emit()


func set_aegis_stage(stage: int) -> void:
	aegis_stage = clampi(stage, 0, MAX_AEGIS_STAGE)
	progress_changed.emit()


func set_domain_stage(stage: int) -> void:
	domain_stage = clampi(stage, 0, MAX_DOMAIN_STAGE)
	progress_changed.emit()


func set_max_masks(masks: int) -> void:
	max_masks = maxi(masks, 1)
	progress_changed.emit()


func unlock_double_jump(unlocked := true) -> void:
	can_double_jump = unlocked
	progress_changed.emit()


func unlock_wall_jump(unlocked := true) -> void:
	can_wall_jump = unlocked
	progress_changed.emit()


func unlock_vision(unlocked := true) -> void:
	vision_unlocked = unlocked
	progress_changed.emit()


func _reset_progress() -> void:
	credits = 0
	max_masks = START_MASKS
	current_masks = -1.0
	dash_level = 0
	can_double_jump = false
	can_wall_jump = false
	vision_unlocked = false
	nullblade_stage = 0
	aegis_stage = 0
	domain_stage = 0


# --- Misiones ---

## Empieza una misión (registrada en QuestDB) y la vuelve la activa. false si ya se había empezado.
func start_quest(quest_id: StringName) -> bool:
	if _quest_progress.has(quest_id):
		return false
	if QuestDB.get_quest(quest_id) == null:
		push_error("GameState: la misión '%s' no está registrada en QuestDB." % quest_id)
		return false
	_quest_progress[quest_id] = 0
	active_quest = quest_id
	quest_started.emit(quest_id)
	return true


## Id del paso actual de la misión ("" si no empezó o ya se completó).
func get_current_step(quest_id: StringName) -> StringName:
	var index: int = _quest_progress.get(quest_id, -2)
	var quest := QuestDB.get_quest(quest_id)
	if index < 0 or quest == null or index >= quest.steps.size():
		return &""
	return quest.steps[index].id


## Completa el paso si es el actual de la misión. Al completar el último paso, la misión termina
## (y empieza next_quest si tiene). Devuelve false si ese no era el paso actual.
func complete_step(quest_id: StringName, step_id: StringName) -> bool:
	if step_id == &"" or get_current_step(quest_id) != step_id:
		return false
	var quest := QuestDB.get_quest(quest_id)
	var next_index: int = _quest_progress[quest_id] + 1
	if next_index < quest.steps.size():
		_quest_progress[quest_id] = next_index
		quest_step_changed.emit(quest_id)
		return true
	_quest_progress[quest_id] = -1
	if active_quest == quest_id:
		active_quest = &""
	quest_completed.emit(quest_id)
	if quest.next_quest != &"":
		start_quest(quest.next_quest)
	return true


func is_quest_completed(quest_id: StringName) -> bool:
	return _quest_progress.get(quest_id, -2) == -1


## Verdadero si la misión ya llegó a ese paso (es el actual o ya pasó) o se completó.
## Con step_id vacío, basta con que la misión haya empezado.
func has_reached_step(quest_id: StringName, step_id: StringName = &"") -> bool:
	if is_quest_completed(quest_id):
		return true
	var index: int = _quest_progress.get(quest_id, -2)
	if index < 0:
		return false
	if step_id == &"":
		return true
	var quest := QuestDB.get_quest(quest_id)
	return quest != null and index >= quest.get_step_index(step_id) and quest.get_step_index(step_id) >= 0


## Texto del objetivo actual ("" si no hay misión activa).
func get_objective_text() -> String:
	var quest := QuestDB.get_quest(active_quest)
	var index: int = _quest_progress.get(active_quest, -2)
	if quest == null or index < 0 or index >= quest.steps.size():
		return ""
	return quest.steps[index].objective


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
		"active_quest": String(active_quest),
		"quests": _keys_to_strings(_quest_progress),
		"player": {
			"credits": credits,
			"max_masks": max_masks,
			"current_masks": current_masks,
			"dash_level": dash_level,
			"can_double_jump": can_double_jump,
			"can_wall_jump": can_wall_jump,
			"vision_unlocked": vision_unlocked,
			"nullblade_stage": nullblade_stage,
			"aegis_stage": aegis_stage,
			"domain_stage": domain_stage,
		},
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
	active_quest = StringName(data.get("active_quest", ""))
	var quests: Dictionary = data.get("quests", {})
	for quest_id: String in quests:
		_quest_progress[StringName(quest_id)] = int(quests[quest_id])
	# Partidas sin progreso del jugador (versiones anteriores) quedan con los valores iniciales.
	# int() porque al pasar por JSON los números vuelven como decimales.
	var player: Dictionary = data.get("player", {})
	credits = int(player.get("credits", 0))
	max_masks = maxi(int(player.get("max_masks", START_MASKS)), 1)
	current_masks = float(player.get("current_masks", -1.0))
	dash_level = clampi(int(player.get("dash_level", 0)), 0, MAX_DASH_LEVEL)
	can_double_jump = bool(player.get("can_double_jump", false))
	can_wall_jump = bool(player.get("can_wall_jump", false))
	vision_unlocked = bool(player.get("vision_unlocked", false))
	nullblade_stage = clampi(int(player.get("nullblade_stage", 0)), 0, MAX_NULLBLADE_STAGE)
	aegis_stage = clampi(int(player.get("aegis_stage", 0)), 0, MAX_AEGIS_STAGE)
	domain_stage = clampi(int(player.get("domain_stage", 0)), 0, MAX_DOMAIN_STAGE)
	stats_changed.emit()
	progress_changed.emit()


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
