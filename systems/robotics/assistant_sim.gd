class_name AssistantSim
extends RoboticsSim
## Estación de FUNCIONES: el asistente modular. Hay que dejar listas las 3 mesas del taller (cable revisado,
## computadora encendida y programa abierto). El jugador arma la función preparar_mesa() con tres instrucciones en
## orden y elige cuántas veces llamarla. Una función agrupa instrucciones con un nombre y se reutiliza.
## Casillas: 0, 1, 2 = instrucciones de la función (revisar el cable, encender la compu, abrir el programa, apagar
## la compu) · 3 = llamar a preparar_mesa() (1 vez, 3 veces).

const TABLES := 3
const ACTIONS: Array[StringName] = [&"cable", &"encender", &"abrir", &"apagar"]
const ACTION_NAMES := { &"cable": "revisar el cable", &"encender": "encender la compu", &"abrir": "abrir el programa",
	&"apagar": "apagar la compu" }
const CALLS: Array[int] = [1, 3]


func run(choices: Array[int]) -> RoboticsRun:
	var result := RoboticsRun.new()
	var body: Array[StringName] = []
	for i in 3:
		body.append(ACTIONS[clampi(choice(choices, i), 0, ACTIONS.size() - 1)])
	var calls := CALLS[clampi(choice(choices, 3), 0, CALLS.size() - 1)]
	var problem := ""
	var ready_tables := 0
	for table in calls:
		var cable := false
		var on := false
		var program := false
		for action in body:
			var error := ""
			match action:
				&"cable":
					cable = true
				&"encender":
					if cable:
						on = true
					else:
						error = "la compu no enciende: el cable no estaba revisado"
				&"abrir":
					if on:
						program = true
					else:
						error = "no se puede abrir el programa con la compu apagada"
				&"apagar":
					on = false
					program = false
			result.steps.append({ "table": table, "action": action, "error": error, "cable": cable, "on": on, "program": program })
			if not error.is_empty() and problem.is_empty():
				problem = "Mesa %d: %s. Dentro de la función, el orden importa." % [table + 1, error]
		if cable and on and program:
			ready_tables += 1
		elif problem.is_empty():
			var missing := "revisar el cable" if not cable else ("encender la compu" if not on else "abrir el programa")
			problem = "La función termina, pero la mesa %d no queda lista: falta %s (o se deshizo después)." % [table + 1, missing]
	result.ok = ready_tables == TABLES
	if result.ok:
		result.feedback = "¡Las tres mesas listas! La función agrupa tres instrucciones con un nombre: tres llamadas en vez de nueve instrucciones. Y si hay que cambiar un paso, se cambia en un solo lugar."
	elif not problem.is_empty():
		result.feedback = problem
	else:
		result.feedback = "La mesa 1 quedó lista, pero hay tres mesas: la función se puede llamar las veces que haga falta."
	return result


func draw(canvas: CanvasItem, rect: Rect2, result: RoboticsRun, progress: float, t: float) -> void:
	var o := rect.position
	var w := rect.size.x
	var h := rect.size.y
	var at := step_at(result, progress)
	var current: Dictionary = result.steps[int(at.x)] if result and at.x >= 0 else {}
	# Estado de cada mesa al momento que se muestra.
	var states: Array[Dictionary] = []
	for k in TABLES:
		states.append({ "cable": false, "on": false, "program": false, "error": false })
	if result:
		var last := result.steps.size() - 1 if progress >= 1.0 else int(at.x)
		for k in last + 1:
			var step: Dictionary = result.steps[k]
			var state: Dictionary = states[step["table"]]
			state["cable"] = step["cable"]
			state["on"] = step["on"]
			state["program"] = step["program"]
			state["error"] = not String(step["error"]).is_empty()
	for k in TABLES:
		var x := o.x + 30 + k * (w - 60) / 3.0
		var desk := Rect2(x, o.y + h * 0.62, (w - 90) / 3.0, 8)
		canvas.draw_rect(desk, Color("6a4a32"))
		var screen := Rect2(desk.position + Vector2(desk.size.x / 2.0 - 18, -34), Vector2(36, 26))
		var state: Dictionary = states[k]
		var screen_color := Color("1a2030")
		if state["program"]:
			screen_color = Color("2a6a8a")
		elif state["on"]:
			screen_color = Color("3a4a6a")
		canvas.draw_rect(screen, screen_color)
		canvas.draw_rect(screen, Color("8a94a8"), false, 1.0)
		if state["program"]:
			canvas.draw_rect(Rect2(screen.position + Vector2(5, 5), Vector2(26, 4)), CYAN)
			canvas.draw_rect(Rect2(screen.position + Vector2(5, 12), Vector2(18, 3)), Color(CYAN, 0.6))
		# Cable (verde si se revisó) y luz de encendido.
		canvas.draw_line(desk.position + Vector2(desk.size.x / 2.0, 8), desk.position + Vector2(desk.size.x / 2.0 + 10, 30),
			OK_COLOR if state["cable"] else DIM, 2.0)
		canvas.draw_circle(screen.end + Vector2(-4, 4), 2.5, OK_COLOR if state["on"] else Color("40404a"))
		if state["error"]:
			text(canvas, screen.position + Vector2(10, -6), "!", 16, BAD)
		text(canvas, desk.position + Vector2(0, 24), "Mesa %d" % (k + 1), 12, INK, desk.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	# El asistente va de mesa en mesa.
	if not current.is_empty():
		var table_x := o.x + 30 + int(current["table"]) * (w - 60) / 3.0 + (w - 90) / 6.0
		var bob := sin(t * 6.0) * 2.0
		var robot := Vector2(table_x - 26, o.y + h * 0.62 - 20 + bob)
		canvas.draw_rect(Rect2(robot + Vector2(-8, -10), Vector2(16, 16)), Color("4a5470"))
		canvas.draw_circle(robot + Vector2(-3, -4), 2.0, CYAN)
		canvas.draw_circle(robot + Vector2(3, -4), 2.0, CYAN)
		var line := "preparar_mesa()  →  %s" % ACTION_NAMES[current["action"]]
		text(canvas, o + Vector2(14, 26), line, 14, BAD if not String(current["error"]).is_empty() else CYAN)
		text(canvas, o + Vector2(14, 46), "llamada %d · mesa %d" % [int(current["table"]) + 1, int(current["table"]) + 1], 12, DIM)
