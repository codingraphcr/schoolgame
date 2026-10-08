extends SceneTree
## Prueba automática: incidentes, pistas, presupuesto y decisiones (autoload GameState).
## Ejecutar: godot --headless --path . --script res://tests/test_decision_system.gd

const PHISHING := "res://data/incidents/phishing_laboratorio.tres"

var _failures := 0
var state: Node
var incident: Incident


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	incident = load(PHISHING)

	_test_incident_data()
	_test_investigation_flow()
	_test_apply_control()
	_test_rejected_controls()
	_test_every_control_balance()
	_test_save_round_trip()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_incident_data() -> void:
	_check(incident != null and incident.id == &"phishing_laboratorio", "carga el incidente de phishing")
	_check(incident.clues.size() == 3, "tiene 3 pistas")
	_check(incident.controls.size() == 5, "tiene 5 medidas")
	_check(incident.clues_to_decide <= incident.clues.size(), "las pistas necesarias existen")
	var ids := {}
	for control in incident.controls:
		ids[control.id] = true
		_check(not control.lesson.is_empty() and not control.consequence.is_empty(),
			"'%s' tiene consecuencia y lección" % control.id)
	_check(ids.size() == incident.controls.size(), "los ids de las medidas no se repiten")


func _test_investigation_flow() -> void:
	state.reset()
	var clue_a: Clue = incident.clues[0]
	var clue_b: Clue = incident.clues[1]
	_check(state.get_incident_state(incident) == Incident.State.INACTIVE, "empieza inactivo")
	_check(not state.find_clue(incident, clue_a), "no cuenta pistas antes de empezar")

	var states: Array[Incident.State] = []
	state.incident_state_changed.connect(func(_i: Incident, s: Incident.State) -> void: states.append(s))
	_check(state.start_incident(incident), "el incidente comienza")
	_check(not state.start_incident(incident), "no comienza dos veces")
	_check(state.find_clue(incident, clue_a), "encuentra la primera pista")
	_check(not state.find_clue(incident, clue_a), "una pista repetida no cuenta")
	_check(state.get_incident_state(incident) == Incident.State.INVESTIGATING, "con 1 pista sigue investigando")
	state.find_clue(incident, clue_b)
	_check(state.get_incident_state(incident) == Incident.State.READY, "con 2 pistas se puede decidir")
	_check(states == [Incident.State.INVESTIGATING, Incident.State.READY], "emite los cambios de estado en orden")


func _test_apply_control() -> void:
	var mfa := _control(&"mfa")
	var budget_before: int = state.budget
	var applied: Array[SecurityControl] = []
	state.control_applied.connect(func(_i: Incident, c: SecurityControl) -> void: applied.append(c))
	_check(state.apply_control(incident, mfa), "aplica la MFA")
	_check(state.budget == budget_before - mfa.cost, "descuenta el costo (%d)" % state.budget)
	_check(state.security == state.START_SECURITY + mfa.security_delta, "sube la seguridad (%d)" % state.security)
	_check(state.trust == state.START_TRUST + mfa.trust_delta, "cambia la confianza (%d)" % state.trust)
	_check(state.get_incident_state(incident) == Incident.State.RESOLVED, "el incidente queda resuelto")
	_check(state.has_flag(&"mfa_activa"), "guarda la marca para consecuencias futuras")
	_check(applied == [mfa], "emite control_applied")
	_check(state.check_control(incident, _control(&"filtro_correo")) == "Este incidente ya fue resuelto.", "explica que ya se resolvió")
	_check(not state.apply_control(incident, _control(&"filtro_correo")), "no se decide dos veces")


func _test_rejected_controls() -> void:
	state.reset()
	var expensive := _control(&"mfa")
	_check(not state.check_control(incident, expensive).is_empty(), "sin evidencia no se puede decidir")
	state.start_incident(incident)
	state.find_clue(incident, incident.clues[0])
	state.find_clue(incident, incident.clues[1])
	state.budget = expensive.cost - 1
	_check(state.check_control(incident, expensive) == "Presupuesto insuficiente.", "detecta presupuesto insuficiente")
	_check(not state.apply_control(incident, expensive), "no aplica sin presupuesto")
	_check(state.budget == expensive.cost - 1, "no cobra si no se aplica")
	var foreign := SecurityControl.new()
	_check(not state.apply_control(incident, foreign), "rechaza medidas de otro incidente")


func _test_every_control_balance() -> void:
	for control in incident.controls:
		state.reset()
		state.start_incident(incident)
		for clue in incident.clues:
			state.find_clue(incident, clue)
		_check(state.apply_control(incident, control), "'%s' se puede pagar con el presupuesto inicial" % control.id)
		_check(state.security >= state.STAT_MIN and state.security <= state.STAT_MAX
			and state.trust >= state.STAT_MIN and state.trust <= state.STAT_MAX,
			"'%s' deja los indicadores en 0-100" % control.id)
	_check(_control(&"ignorar").cost == 0 and _control(&"ignorar").security_delta < 0, "ignorar es gratis pero baja la seguridad")


func _test_save_round_trip() -> void:
	state.reset()
	state.start_incident(incident)
	state.find_clue(incident, incident.clues[2])
	state.find_clue(incident, incident.clues[0])
	state.apply_control(incident, _control(&"capacitacion"))
	var saved: Dictionary = state.to_dict()
	var json := JSON.stringify(saved)
	state.reset()
	state.from_dict(JSON.parse_string(json))
	_check(state.budget == saved.budget and state.security == saved.security and state.trust == saved.trust,
		"guardar y cargar conserva los indicadores")
	_check(state.get_incident_state(incident) == Incident.State.RESOLVED, "conserva el estado del incidente")
	_check(state.has_clue(incident.clues[2]) and not state.has_clue(incident.clues[1]), "conserva las pistas")
	_check(state.has_flag(&"capacitacion_phishing"), "conserva las marcas")
	_check(state.get_decision_log().size() == 1, "conserva el historial de decisiones")


func _control(id: StringName) -> SecurityControl:
	for control in incident.controls:
		if control.id == id:
			return control
	push_error("No existe la medida '%s'" % id)
	return null


func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK   ", message)
	else:
		_failures += 1
		print("FAIL ", message)
