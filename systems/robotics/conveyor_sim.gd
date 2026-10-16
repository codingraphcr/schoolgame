class_name ConveyorSim
extends RoboticsSim
## Estación de CICLOS: la cinta automática. Hay 5 cajas; el programa es «repetir [cuántas veces]: mover la cinta» con
## una condición de salida «detener cuando [...]». Tiene que mover las 5 cajas y detenerse justo ahí. Si el ciclo
## no tiene salida, la cinta sigue girando vacía: la simulación lo corta por seguridad al llegar a SAFETY_LIMIT
## vueltas (anticipa a Bucle, que no sabe detenerse).
## Casillas: 0 = repetir (para siempre, 3 veces, 8 veces) · 1 = detener cuando (nunca, no queden cajas, se hayan
## movido 3 cajas).

const BOXES := 5
const LIMITS: Array[int] = [-1, 3, 8]


func run(choices: Array[int]) -> RoboticsRun:
	var result := RoboticsRun.new()
	var limit := LIMITS[clampi(choice(choices, 0), 0, LIMITS.size() - 1)]
	var exit_rule := clampi(choice(choices, 1), 0, 2)
	var boxes := BOXES
	var moved := 0
	var empty_turns := 0
	var turn := 0
	while true:
		if limit >= 0 and turn >= limit:
			break
		if (exit_rule == 1 and boxes == 0) or (exit_rule == 2 and moved >= 3):
			break
		if turn >= SAFETY_LIMIT:
			result.stopped_for_safety = true
			break
		var empty := boxes == 0
		if empty:
			empty_turns += 1
		else:
			boxes -= 1
			moved += 1
		turn += 1
		result.steps.append({ "turn": turn, "boxes": boxes, "moved": moved, "empty": empty })
	result.ok = moved == BOXES and empty_turns == 0 and not result.stopped_for_safety
	if result.ok:
		result.feedback = "¡Listo! El ciclo repite «mover la cinta» y la condición de salida lo detiene justo cuando no quedan cajas."
	elif result.stopped_for_safety:
		result.feedback = "La cinta nunca se detuvo: el ciclo no tenía condición de salida. La simulación lo cortó por seguridad; una máquina de verdad seguiría girando para siempre."
	elif moved < BOXES:
		result.feedback = "El ciclo terminó con %d %s todavía en la cinta: se detuvo antes de tiempo." % [boxes, "caja" if boxes == 1 else "cajas"]
	else:
		result.feedback = "Movió las 5 cajas, pero la cinta siguió girando vacía %d %s más. Hace falta detenerla cuando ya no queden cajas." % [
			empty_turns, "vuelta" if empty_turns == 1 else "vueltas"]
	return result


func duration(result: RoboticsRun) -> float:
	return clampf(result.steps.size() * 0.45, 1.5, 6.5)


func draw(canvas: CanvasItem, rect: Rect2, result: RoboticsRun, progress: float, t: float) -> void:
	var o := rect.position
	var w := rect.size.x
	var h := rect.size.y
	var belt := Rect2(o.x + 20, o.y + h * 0.55, w - 130, 12)
	var bin := Rect2(o.x + w - 100, o.y + h * 0.55 - 30, 80, 60)
	var at := step_at(result, progress)
	var step: Dictionary = result.steps[int(at.x)] if result and at.x >= 0 else {}
	var moving := result != null and progress < 1.0 and not step.is_empty()
	var boxes_left := BOXES
	var in_bin := 0
	if not step.is_empty():
		# La caja que viaja ya salió de la fila y todavía no llegó al final.
		boxes_left = int(step["boxes"])
		in_bin = int(step["moved"]) - (1 if moving and not step["empty"] else 0)
	# Cinta con rodillos que giran mientras corre el ciclo.
	canvas.draw_rect(belt, BELT)
	for k in 9:
		var spin := t * 40.0 if moving else 0.0
		var roller_x := belt.position.x + fmod(k * (belt.size.x / 9.0) + spin, belt.size.x)
		canvas.draw_circle(Vector2(roller_x, belt.get_center().y), 3.5, Color(DIM, 0.7))
	canvas.draw_rect(bin, Color(0.1, 0.13, 0.2))
	canvas.draw_rect(bin, CYAN, false, 1.5)
	text(canvas, bin.position + Vector2(0, -6), "AL FINAL", 11, INK)
	# Cajas esperando, la que viaja y las que ya llegaron.
	for k in boxes_left:
		_box(canvas, Vector2(belt.position.x + 14 + k * 20, belt.position.y - 9))
	if moving and not step["empty"]:
		_box(canvas, Vector2(belt.position.x + 14, belt.position.y - 9).lerp(Vector2(belt.end.x - 6, belt.position.y - 9), at.y))
	for k in in_bin:
		_box(canvas, bin.position + Vector2(14 + (k % 3) * 22, 40 - int(k / 3.0) * 16))
	# Contador de vueltas y avisos.
	if not step.is_empty():
		text(canvas, o + Vector2(20, 24), "Vuelta %d" % step["turn"], 16, INK)
		if step["empty"]:
			text(canvas, o + Vector2(20, 44), "(la cinta gira vacía)", 13, BAD)
	if result and progress >= 1.0 and result.stopped_for_safety:
		canvas.draw_rect(Rect2(o + Vector2(10, h - 44), Vector2(w - 20, 32)), Color(BAD, 0.2))
		text(canvas, o + Vector2(0, h - 22), "DETENIDO POR SEGURIDAD · EL CICLO NO IBA A TERMINAR", 13, BAD, w, HORIZONTAL_ALIGNMENT_CENTER)


func _box(canvas: CanvasItem, pos: Vector2) -> void:
	canvas.draw_rect(Rect2(pos + Vector2(-8, -8), Vector2(16, 16)), Color("c8a060"))
	canvas.draw_rect(Rect2(pos + Vector2(-8, -8), Vector2(16, 16)), Color("6a4a2a"), false, 1.0)
	canvas.draw_line(pos + Vector2(-8, -2), pos + Vector2(8, -2), Color("6a4a2a"), 1.0)
