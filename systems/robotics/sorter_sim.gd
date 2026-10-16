class_name SorterSim
extends RoboticsSim
## Estación de CONDICIONALES: el robot clasificador. Por la cinta pasan latas (metal), papeles y botellas
## (plástico); el programa es «si el objeto es [categoría] → [ruta]; si no → [ruta]». Las latas tienen que ir a la
## Ruta A (metales) y todo lo demás a la Ruta B.
## Casillas: 0 = categoría (metal, papel, plástico) · 1 = ruta del «si» (A, B) · 2 = ruta del «si no» (A, B).

const ITEMS: Array[StringName] = [&"metal", &"papel", &"plastico", &"metal", &"papel", &"metal"]
const CATEGORIES: Array[StringName] = [&"metal", &"papel", &"plastico"]
const ITEM_NAMES := { &"metal": "La lata", &"papel": "El papel", &"plastico": "La botella" }
const ROUTE_NAMES: Array[String] = ["Ruta A (metales)", "Ruta B (otros)"]


func run(choices: Array[int]) -> RoboticsRun:
	var result := RoboticsRun.new()
	var category: StringName = CATEGORIES[clampi(choice(choices, 0), 0, CATEGORIES.size() - 1)]
	var if_route := clampi(choice(choices, 1), 0, 1)
	var else_route := clampi(choice(choices, 2), 0, 1)
	var first_wrong := -1
	for i in ITEMS.size():
		var item := ITEMS[i]
		var matches := item == category
		var route := if_route if matches else else_route
		var expected := 0 if item == &"metal" else 1
		result.steps.append({ "item": item, "matches": matches, "route": route, "correct": route == expected })
		if route != expected and first_wrong < 0:
			first_wrong = i
	result.ok = first_wrong < 0
	if result.ok:
		result.feedback = "¡Todo a su lugar! El «si» manda las latas a la Ruta A y el «si no» se encarga de todo lo demás."
	elif if_route == else_route:
		result.feedback = "Las dos ramas mandan a la %s: así la condición no decide nada. El «si» y el «si no» tienen que ir a rutas distintas." % ROUTE_NAMES[if_route]
	else:
		var step: Dictionary = result.steps[first_wrong]
		var expected_route := 0 if step["item"] == &"metal" else 1
		result.feedback = "%s fue a la %s, pero tenía que ir a la %s. ¿El «si» pregunta por lo que hay que separar?" % [
			ITEM_NAMES[step["item"]], ROUTE_NAMES[step["route"]], ROUTE_NAMES[expected_route]]
	return result


func draw(canvas: CanvasItem, rect: Rect2, result: RoboticsRun, progress: float, t: float) -> void:
	var o := rect.position
	var w := rect.size.x
	var h := rect.size.y
	var belt_y := o.y + h * 0.5
	var fork_x := o.x + w * 0.55
	# Cinta, desvío y las dos rutas con su caja.
	canvas.draw_rect(Rect2(o.x + 10, belt_y - 6, fork_x - o.x - 10, 12), BELT)
	for k in 8:
		var roller_x := o.x + 18 + fmod(k * 26.0 + t * 30.0, fork_x - o.x - 20)
		canvas.draw_circle(Vector2(roller_x, belt_y), 3.0, Color(DIM, 0.6))
	var bin_a := Rect2(o.x + w - 90, o.y + 12, 78, 54)
	var bin_b := Rect2(o.x + w - 90, o.y + h - 66, 78, 54)
	canvas.draw_line(Vector2(fork_x, belt_y), bin_a.get_center() - Vector2(39, 0), BELT, 8.0)
	canvas.draw_line(Vector2(fork_x, belt_y), bin_b.get_center() - Vector2(39, 0), BELT, 8.0)
	for data in [[bin_a, "RUTA A · metales"], [bin_b, "RUTA B · otros"]]:
		var bin: Rect2 = data[0]
		canvas.draw_rect(bin, Color(0.1, 0.13, 0.2))
		canvas.draw_rect(bin, CYAN, false, 1.5)
		text(canvas, bin.position + Vector2(4, -4), data[1], 11, INK)
	# El robot que decide en el desvío.
	canvas.draw_rect(Rect2(fork_x - 12, belt_y - 40, 24, 22), Color("4a5470"))
	canvas.draw_circle(Vector2(fork_x - 5, belt_y - 30), 2.5, CYAN)
	canvas.draw_circle(Vector2(fork_x + 5, belt_y - 30), 2.5, CYAN)
	if result == null:
		for k in ITEMS.size():
			_item(canvas, ITEMS[k], Vector2(o.x + 24 + k * 22, belt_y - 12), Color.WHITE)
		return
	var at := step_at(result, progress)
	var counts: Array[int] = [0, 0]
	for k in result.steps.size():
		var step: Dictionary = result.steps[k]
		var bin: Rect2 = bin_a if step["route"] == 0 else bin_b
		if k < at.x or progress >= 1.0:
			var slot := counts[step["route"]]
			counts[step["route"]] += 1
			var pos := bin.position + Vector2(12 + (slot % 5) * 14, 30)
			_item(canvas, step["item"], pos, Color.WHITE)
			text(canvas, pos + Vector2(-4, 18), "✓" if step["correct"] else "✗", 12, OK_COLOR if step["correct"] else BAD)
		elif k == int(at.x):
			var start := Vector2(o.x + 24, belt_y - 12)
			var fork := Vector2(fork_x, belt_y - 12)
			var target := bin.position + Vector2(40, 30)
			var pos := start.lerp(fork, at.y / 0.6) if at.y < 0.6 else fork.lerp(target, (at.y - 0.6) / 0.4)
			_item(canvas, step["item"], pos, Color.WHITE)
			var line := "%s → %s" % ["SI" if step["matches"] else "SI NO", ROUTE_NAMES[step["route"]]]
			text(canvas, Vector2(fork_x - 60, belt_y - 50), line, 12, CYAN)
		else:
			# En espera, en fila sobre la cinta (los que no caben todavía no se ven).
			var wait_x := o.x + 24 + (k - int(at.x)) * 22.0
			if wait_x < fork_x - 30:
				_item(canvas, step["item"], Vector2(wait_x, belt_y - 12), Color(1, 1, 1, 0.5))


func _item(canvas: CanvasItem, item: StringName, pos: Vector2, tint: Color) -> void:
	match item:
		&"metal":
			canvas.draw_rect(Rect2(pos + Vector2(-5, -8), Vector2(10, 14)), Color("b8c0cc") * tint)
			canvas.draw_rect(Rect2(pos + Vector2(-5, -8), Vector2(10, 3)), Color("8a929e") * tint)
		&"papel":
			canvas.draw_rect(Rect2(pos + Vector2(-6, -6), Vector2(12, 12)), Color("f4f0e4") * tint)
			canvas.draw_line(pos + Vector2(-4, -2), pos + Vector2(4, -2), Color(0.4, 0.4, 0.5) * tint, 1.0)
		_:
			canvas.draw_rect(Rect2(pos + Vector2(-4, -10), Vector2(8, 16)), Color(0.6, 0.85, 1.0, 0.8) * tint)
			canvas.draw_rect(Rect2(pos + Vector2(-2, -13), Vector2(4, 3)), Color("4f81bd") * tint)
