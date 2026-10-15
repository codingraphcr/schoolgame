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
signal quest_started(quest_id: StringName)
signal quest_step_changed(quest_id: StringName)
signal quest_completed(quest_id: StringName)

const STAT_MIN := 0
const STAT_MAX := 100

const START_BUDGET := 10000
const START_SECURITY := 35
const START_TRUST := 60

const START_MASKS := 4
## Fragmentos de vida que forman una vida nueva (un cristal de integridad completo).
const LIFE_FRAGMENTS_PER_MASK := 4
## Fragmentos de energía que forman una barrita de energía más.
const ENERGY_FRAGMENTS_PER_CELL := 4
## Barritas de energía al empezar (suben con la historia).
const START_ENERGY_CELLS := 2
const MAX_ENERGY_CELLS := 8
const MAX_DASH_LEVEL := 3
const MAX_NULLBLADE_STAGE := 4
const MAX_AEGIS_STAGE := 3
const MAX_DOMAIN_STAGE := 3
## Fracción de los créditos que se pierde al morir.

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

var max_masks := START_MASKS
## Máscaras actuales al salir de una sala (-1 = llenas). Así cambiar de sala no cura.
var current_masks := -1.0
## Fragmentos de vida juntados hacia la próxima vida (0 a LIFE_FRAGMENTS_PER_MASK - 1).
var life_fragments := 0
## Fragmentos de energía juntados hacia la próxima barrita (0 a ENERGY_FRAGMENTS_PER_CELL - 1).
var energy_fragments := 0
## Barritas de energía para habilidades (el HUD las muestra debajo de los cristales).
var max_energy_cells := START_ENERGY_CELLS
## Energía al salir de una sala, en barritas (-1 = llena). Así cambiar de sala no la recarga.
var current_energy := -1.0
## 0 = sin dash · 1 Dash · 2 Dash Fantasma · 3 Esquiva Perfecta.
var dash_level := 0
var can_double_jump := false
var can_wall_jump := false
var vision_unlocked := false
## Inmersión Digital (Capítulo 1): entrar por la conexión de un monitor a un entorno digital.
## No es lo mismo que la Visión Digital (que solo deja ver). Permanente.
var immersion_unlocked := false
## 0 = no obtenida · 1 .exe · 2 .zero · 3 .void · 4 .max
var nullblade_stage := 0
## 0 = no obtenido · 1 Pulse · 2 Bridge · 3 Sync
var aegis_stage := 0
## 0 = bloqueado · 1, 2, 3 = versiones I, II, III
var domain_stage := 0
## Carga del Dominio Nulo (no se guarda: se mantiene entre salas durante la sesión).
var domain_charge := 0.0
## Segundos jugados en esta partida (solo cuentan dentro de una sala y sin pausa: ver Room).
var play_time := 0.0

# --- Misiones ---
## Misión que se muestra como OBJETIVO (vacío = ninguna).
var active_quest: StringName = &""
## Paso actual de cada misión empezada (índice); -1 = completada.
var _quest_progress: Dictionary[StringName, int] = {}

# --- Conocimiento ---
## Comandos de terminal que Kai ya usó (páginas del manual del Grimorio).
var _commands: Dictionary[StringName, bool] = {}
## Contraseñas creadas por el jugador (p. ej. la del profesor). Solo la huella con sal, nunca el
## texto: { id: { "salt", "hash", "backup_salt", "backup_hash" } }.
var _passwords: Dictionary[StringName, Dictionary] = {}


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
	_commands.clear()
	_passwords.clear()
	_economy().reset()
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


## Quita una marca (para rehacer algo: p. ej. volver a pelear contra un jefe en las pruebas).
func clear_flag(flag: StringName) -> void:
	_flags.erase(flag)


## Kai encuentra el Grimorio en el cuarto viejo (H5). Hasta entonces G no lo abre; lo aprendido
## antes (comandos, conceptos) ya queda anotado y aparece en sus páginas al encontrarlo.
const GRIMORIO_FLAG := &"grimorio_obtenido"


func has_grimorio() -> bool:
	return has_flag(GRIMORIO_FLAG)


func get_decision_log() -> Array[Dictionary]:
	return _decision_log.duplicate(true)


func _set_incident_state(incident: Incident, state: Incident.State) -> void:
	_incident_states[incident.id] = state
	incident_state_changed.emit(incident, state)


# --- Progreso del jugador ---

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


## Más barritas de energía (al avanzar en la historia).
func set_max_energy_cells(cells: int) -> void:
	max_energy_cells = clampi(cells, 1, MAX_ENERGY_CELLS)
	progress_changed.emit()


## Suma un fragmento de vida. Al juntar LIFE_FRAGMENTS_PER_MASK se forma una vida nueva (llena):
## devuelve true en ese caso.
func add_life_fragment() -> bool:
	life_fragments += 1
	var completed := life_fragments >= LIFE_FRAGMENTS_PER_MASK
	if completed:
		life_fragments = 0
		max_masks += 1
		current_masks = -1.0
	progress_changed.emit()
	return completed


## Suma un fragmento de energía. Al juntar ENERGY_FRAGMENTS_PER_CELL se agrega una barrita de energía
## (llena): devuelve true en ese caso.
func add_energy_fragment() -> bool:
	energy_fragments += 1
	var completed := energy_fragments >= ENERGY_FRAGMENTS_PER_CELL
	if completed:
		energy_fragments = 0
		max_energy_cells = mini(max_energy_cells + 1, MAX_ENERGY_CELLS)
		current_energy = -1.0
	progress_changed.emit()
	return completed


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


func unlock_immersion(unlocked := true) -> void:
	immersion_unlocked = unlocked
	progress_changed.emit()


func _reset_progress() -> void:
	max_masks = START_MASKS
	life_fragments = 0
	energy_fragments = 0
	max_energy_cells = START_ENERGY_CELLS
	current_energy = -1.0
	current_masks = -1.0
	dash_level = 0
	can_double_jump = false
	can_wall_jump = false
	vision_unlocked = false
	immersion_unlocked = false
	nullblade_stage = 0
	aegis_stage = 0
	domain_stage = 0
	domain_charge = 0.0
	play_time = 0.0


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
	var quest := QuestDB.get_quest(quest_id)
	if quest.start_flag != &"":
		set_flag(quest.start_flag)
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
	# Recompensa única: aunque se repitiera el último paso, no se cobra dos veces.
	if quest.ecos_reward > 0:
		_economy().claim_reward(StringName("mision:%s" % quest_id), quest.ecos_reward)
	if quest.completion_flag != &"":
		set_flag(quest.completion_flag)
	for flag in quest.extra_completion_flags:
		set_flag(flag)
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
## Sala del mapa a la que hay que ir para el objetivo actual (QuestStep.room_id), o vacío.
func get_objective_room() -> StringName:
	var quest := QuestDB.get_quest(active_quest)
	var index: int = _quest_progress.get(active_quest, -2)
	if quest == null or index < 0 or index >= quest.steps.size():
		return &""
	return quest.steps[index].room_id


func get_objective_text() -> String:
	var quest := QuestDB.get_quest(active_quest)
	var index: int = _quest_progress.get(active_quest, -2)
	if quest == null or index < 0 or index >= quest.steps.size():
		return ""
	return quest.steps[index].objective


# --- Conocimiento ---

## Registra un comando de terminal como aprendido. true si es nuevo.
func learn_command(command: StringName) -> bool:
	if _commands.has(command):
		return false
	_commands[command] = true
	return true


func has_learned_command(command: StringName) -> bool:
	return _commands.has(command)


func get_learned_commands() -> Array[String]:
	return _key_list(_commands)


# --- Contraseñas del jugador ---
# Como en los sistemas reales, se guarda la huella (hash SHA-256 con sal), no la contraseña:
# ni el archivo de guardado ni otra persona pueden leerla. El jugador tiene que recordarla.

## Guarda la huella de una contraseña (y de su código de respaldo, si se da). Reemplaza la anterior.
## Rechaza (false) un texto vacío, demasiado largo o con caracteres no permitidos (PasswordRules.sanitize):
## así nada que no sea una contraseña llega al guardado.
func set_password(id: StringName, password: String, backup_code := "") -> bool:
	if id == &"" or not PasswordRules.is_clean(password) or backup_code.length() > 16:
		push_warning("GameState: contraseña rechazada (vacía, muy larga o con caracteres no permitidos).")
		return false
	var entry := { "salt": _new_salt(), "hash": "", "backup_salt": "", "backup_hash": "" }
	entry["hash"] = _fingerprint(entry["salt"], password)
	if not backup_code.is_empty():
		entry["backup_salt"] = _new_salt()
		entry["backup_hash"] = _fingerprint(entry["backup_salt"], backup_code.strip_edges().to_upper())
	_passwords[id] = entry
	return true


func has_password(id: StringName) -> bool:
	return _passwords.has(id)


## Si el intento coincide con la contraseña guardada (distingue mayúsculas, como los sistemas reales).
func check_password(id: StringName, attempt: String) -> bool:
	var entry: Dictionary = _passwords.get(id, {})
	return not entry.is_empty() and _fingerprint(entry["salt"], attempt) == entry["hash"]


## Si el código de respaldo es correcto (para recuperar la cuenta si se olvida la contraseña).
func check_backup_code(id: StringName, code: String) -> bool:
	var entry: Dictionary = _passwords.get(id, {})
	return not entry.is_empty() and not String(entry["backup_hash"]).is_empty() 		and _fingerprint(entry["backup_salt"], code.strip_edges().to_upper()) == entry["backup_hash"]


## La economía (saldo de Ecos) es su propio autoload; GameState la guarda y reinicia con el resto.
func _economy() -> Node:
	return get_node("/root/Economy")


static func _fingerprint(salt: String, text: String) -> String:
	return (salt + text).sha256_text()


static func _new_salt() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()


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
		"economy": _economy().to_dict(),
		"commands": _key_list(_commands),
		"passwords": _keys_to_strings(_passwords),
		"player": {
			"max_masks": max_masks,
			"current_masks": current_masks,
			"life_fragments": life_fragments,
			"energy_fragments": energy_fragments,
			"max_energy_cells": max_energy_cells,
			"current_energy": current_energy,
			"dash_level": dash_level,
			"can_double_jump": can_double_jump,
			"can_wall_jump": can_wall_jump,
			"vision_unlocked": vision_unlocked,
			"immersion_unlocked": immersion_unlocked,
			"nullblade_stage": nullblade_stage,
			"aegis_stage": aegis_stage,
			"domain_stage": domain_stage,
		},
		"play_time": int(play_time),
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
	for command: String in data.get("commands", []):
		_commands[StringName(command)] = true
	var passwords: Dictionary = data.get("passwords", {})
	for password_id: String in passwords:
		_passwords[StringName(password_id)] = (passwords[password_id] as Dictionary).duplicate()
	# Partidas sin progreso del jugador (versiones anteriores) quedan con los valores iniciales.
	# int() porque al pasar por JSON los números vuelven como decimales.
	var player: Dictionary = data.get("player", {})
	# Las partidas de antes de los Ecos guardaban «credits»: se convierten.
	_economy().from_dict(data.get("economy", {}), int(player.get("credits", 0)))
	max_masks = maxi(int(player.get("max_masks", START_MASKS)), 1)
	current_masks = float(player.get("current_masks", -1.0))
	life_fragments = clampi(int(player.get("life_fragments", 0)), 0, LIFE_FRAGMENTS_PER_MASK - 1)
	energy_fragments = clampi(int(player.get("energy_fragments", 0)), 0, ENERGY_FRAGMENTS_PER_CELL - 1)
	max_energy_cells = clampi(int(player.get("max_energy_cells", START_ENERGY_CELLS)), 1, MAX_ENERGY_CELLS)
	current_energy = float(player.get("current_energy", -1.0))
	dash_level = clampi(int(player.get("dash_level", 0)), 0, MAX_DASH_LEVEL)
	can_double_jump = bool(player.get("can_double_jump", false))
	can_wall_jump = bool(player.get("can_wall_jump", false))
	vision_unlocked = bool(player.get("vision_unlocked", false))
	immersion_unlocked = bool(player.get("immersion_unlocked", false))
	nullblade_stage = clampi(int(player.get("nullblade_stage", 0)), 0, MAX_NULLBLADE_STAGE)
	aegis_stage = clampi(int(player.get("aegis_stage", 0)), 0, MAX_AEGIS_STAGE)
	domain_stage = clampi(int(player.get("domain_stage", 0)), 0, MAX_DOMAIN_STAGE)
	play_time = maxf(float(data.get("play_time", 0)), 0.0)
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
