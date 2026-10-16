class_name SequenceSim
extends RoboticsSim
## SECUENCIAS: el robot de la Compañera («El robot que no obedece», tarea del Capítulo 2). El robot empieza abajo a
## la izquierda de una mesa de 3 × 3 (mirando a la derecha) con una pieza, y tiene que dejarla en la caja de arriba a
## la derecha. Las instrucciones se ejecutan una tras otra, en orden: si el orden está mal, el robot choca con el borde
## o suelta la pieza en otro lado.
## Casillas: 0–3 = instrucción (avanzar 2, girar a la izquierda, girar a la derecha, soltar la pieza).

const SIZE := 3
const START := Vector2i(0, 2)
const GOAL := Vector2i(2, 0)
const ACTIONS: Array[StringName] = [&"avanzar", &"izquierda", &"derecha", &"soltar"]
const ACTION_NAMES := { &"avanzar": "avanzar 2", &"izquierda": "girar a la izquierda", &"derecha": "girar a la derecha",
	&"soltar": "soltar la pieza" }


func run(choices: Array[int]) -> RoboticsRun:
	var result := RoboticsRun.new()
	var cell := START
	var facing := Vector2i.RIGHT
	var carrying := true
	var dropped_at := Vector2i(-1, -1)
	var problem := ""
	for i in 4:
		var action := ACTIONS[clampi(choice(choices, i), 0, ACTIONS.size() - 1)]
		var error := ""
		match action:
			&"avanzar":
				var target := cell + facing * 2
				if target.x < 0 or target.y < 0 or target.x >= SIZE or target.y >= SIZE:
					error = "el robot choca con el borde de la mesa"
				else:
					cell = target
			&"izquierda":
				facing = Vector2i(facing.y, -facing.x)
			&"derecha":
				facing = Vector2i(-facing.y, facing.x)
			&"soltar":
				if carrying:
					carrying = false
					dropped_at = cell
		result.steps.append({ "action": action, "cell": cell, "facing": facing, "carrying": carrying, "error": error })
		if not error.is_empty():
			problem = "Instrucción %d (%s): %s. Las instrucciones se ejecutan en orden, una tras otra." % [i + 1, ACTION_NAMES[action], error]
			break
	result.ok = problem.is_empty() and dropped_at == GOAL
	if result.ok:
		result.feedback = "¡La pieza llegó a la caja! Una secuencia es una lista de instrucciones en orden: el mismo paso en otro lugar cambia todo."
	elif not problem.is_empty():
		result.feedback = problem
	elif carrying:
		result.feedback = "El robot terminó con la pieza todavía en la mano: falta soltarla (y en el lugar correcto)."
	else:
		result.feedback = "El robot soltó la pieza en otro lado: soltar tiene que ir después de llegar a la caja."
	return result


func draw(canvas: CanvasItem, rect: Rect2, result: RoboticsRun, progress: float, t: float) -> void:
	var cell_size := minf(rect.size.x, rect.size.y - 40.0) / SIZE
	var origin := rect.position + Vector2((rect.size.x - cell_size * SIZE) / 2.0, 30)
	for y in SIZE:
		for x in SIZE:
			var r := Rect2(origin + Vector2(x, y) * cell_size, Vector2(cell_size, cell_size)).grow(-2)
			canvas.draw_rect(r, Color(0.12, 0.15, 0.22))
			canvas.draw_rect(r, Color(DIM, 0.4), false, 1.0)
	var goal_rect := Rect2(origin + Vector2(GOAL) * cell_size, Vector2(cell_size, cell_size)).grow(-14)
	canvas.draw_rect(goal_rect, Color("6a4a32"))
	canvas.draw_rect(goal_rect, Color("c8a060"), false, 2.0)
	text(canvas, goal_rect.position + Vector2(0, -4), "CAJA", 11, INK)
	var cell := START
	var facing := Vector2i.RIGHT
	var carrying := true
	var dropped := Vector2i(-1, -1)
	var line := ""
	var bad := false
	if result:
		var at := step_at(result, progress)
		var last := result.steps.size() - 1 if progress >= 1.0 else int(at.x)
		for k in last + 1:
			var step: Dictionary = result.steps[k]
			if carrying and not step["carrying"]:
				dropped = step["cell"]
			cell = step["cell"]
			facing = step["facing"]
			carrying = step["carrying"]
			line = "%d. %s" % [k + 1, ACTION_NAMES[step["action"]]]
			bad = not String(step["error"]).is_empty()
	var center := origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size
	canvas.draw_rect(Rect2(center - Vector2(16, 14), Vector2(32, 28)), Color("4a5470"))
	canvas.draw_circle(center + Vector2(facing) * 10.0, 4.0, CYAN)
	if carrying:
		canvas.draw_rect(Rect2(center + Vector2(-6, -24), Vector2(12, 10)), Color("c8a060"))
	if dropped.x >= 0:
		var drop_center := origin + (Vector2(dropped) + Vector2(0.5, 0.5)) * cell_size
		canvas.draw_rect(Rect2(drop_center + Vector2(10, 4), Vector2(12, 10)), Color("c8a060"))
	if not line.is_empty():
		text(canvas, rect.position + Vector2(4, 18), line, 14, BAD if bad else CYAN)
