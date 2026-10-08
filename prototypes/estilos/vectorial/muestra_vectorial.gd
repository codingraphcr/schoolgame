extends StyleSample
## Muestra B: estilo vectorial con animación por huesos (Hollow Knight simplificado).
## Mismo recorrido que la muestra A, dibujado con formas suaves, degradados y contornos finos.
## Usa la misma escala del proyecto (cámara ×2): los polígonos se ven nítidos igual.

const VectorKai := preload("res://prototypes/estilos/vectorial/vector_kai.gd")

const N0 := Color("080b18")
const N1 := Color("121a33")
const N2 := Color("1b2647")
const N3 := Color("26355e")
const N4 := Color("34477a")
const N5 := Color("4a5f96")
const WOOD_D := Color("5a3826")
const WOOD := Color("8a5a3a")
const WOOD_L := Color("b9824f")
const TEAL_D := Color("1e4f5c")
const TEAL := Color("2f7383")
const TEAL_L := Color("4fa3ac")
const PAPER := Color("e9dfc6")
const PAPER_D := Color("b8ab8c")
const CORK := Color("9a6a42")
const HOOD := Color("e0913a")
const MET_D := Color("3a4462")
const MET := Color("5a6788")
const MET_L := Color("8b98b8")
const CYAN := Color("3ef2ff")
const CYAN_M := Color("1fa5c4")
const CYAN_D := Color("146a8a")
const MAG := Color("ff3ea5")
const MAG_D := Color("9c1f6e")
const LED_G := Color("59ff9c")
const LED_A := Color("ffb347")
const LED_R := Color("ff4d4d")
const OUTLINE := VectorCanvas.OUTLINE

const HANGER_SPACING := 64.0


func _init() -> void:
	sample_title = "MUESTRA B · Vectorial con animación por huesos (misma escala del proyecto)"
	other_sample = "res://prototypes/estilos/mixta/muestra_mixta.tscn"
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _build_art() -> void:
	add_ambient(Color(0.62, 0.66, 0.85))
	_canvas(_paint_wall)
	_canvas(_paint_circuits, true)
	_canvas(_paint_ceiling, true)
	_canvas(_paint_corridor_decor, true)
	_canvas(_paint_lockers)
	_canvas(_paint_trays)
	_canvas(_paint_lab, true)
	_canvas(_paint_floor)
	_canvas(_paint_corruption, true)
	_canvas(_paint_lure, true)
	_add_dust()
	_add_lights()


func _build_player_visual() -> Node2D:
	var kai := VectorKai.new()
	kai.player = player
	return kai


func _canvas(painter: Callable, animated := false) -> VectorCanvas:
	var canvas := VectorCanvas.new()
	canvas.painter = painter
	canvas.animated = animated
	add_child(canvas)
	return canvas


func _add_lights() -> void:
	for x in range(40, int(LAB_X), 128):
		add_light(Vector2(x + 11, CEILING_Y + 30), Color(1.0, 0.85, 0.6), 120, 0.45)
	add_light(Vector2(192, 210), Color(0.45, 0.6, 1.0), 70, 0.5)
	add_light(Vector2(304, 210), Color(0.45, 0.6, 1.0), 70, 0.5)
	add_light(Vector2(247, 268), Color(0.25, 0.85, 1.0), 40, 0.6)
	add_light(Vector2(353, 152), Color(0.25, 0.95, 1.0), 60, 0.9)
	add_light(Vector2(787, 118), Color(0.25, 0.95, 1.0), 110, 1.1)
	for i in 2:
		add_light(Vector2(726 + i * 30, 270), Color(0.35, 1.0, 0.6), 50, 0.6)
	add_light(LURE_POSITION + Vector2(0, 4), Color(1.0, 0.25, 0.65), 90, 1.2)
	add_light(CORRUPTION.get_center(), Color(1.0, 0.25, 0.65), 70, 0.8)


## Motas de datos flotando: dan profundidad y atmósfera.
func _add_dust() -> void:
	var dust := CPUParticles2D.new()
	dust.amount = 70
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.position = Vector2(ROOM_SIZE.x * 0.5, 200)
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(ROOM_SIZE.x * 0.5, 120)
	dust.direction = Vector2(0, -1)
	dust.spread = 40.0
	dust.gravity = Vector2(0, -2)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 6.0
	dust.scale_amount_min = 0.8
	dust.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(CYAN, 0.0))
	ramp.add_point(0.3, Color(CYAN, 0.55))
	ramp.set_color(ramp.get_point_count() - 1, Color(CYAN, 0.0))
	dust.color_ramp = ramp
	add_child(dust)


# =====================================================================
# Pintores (coordenadas del mundo)
# =====================================================================

func _paint_wall(c: VectorCanvas, _t: float) -> void:
	# Pasillo.
	c.gradient_rect(Rect2(0, 0, LAB_X, FLOOR_Y), N1, N2)
	for x in range(0, int(LAB_X), 48):
		c.draw_line(Vector2(x, CEILING_Y), Vector2(x, 288), Color(N1, 0.9), 1.0, true)
	c.gradient_box(Rect2(-2, 164, LAB_X + 2, 7), 1.5, N5, N3)
	c.gradient_box(Rect2(-2, 288, LAB_X + 2, 16), 1.0, TEAL, TEAL_D)
	# Laboratorio: pared tecnológica más oscura.
	c.gradient_rect(Rect2(LAB_X, 0, ROOM_SIZE.x - LAB_X, FLOOR_Y), Color("0b1124"), Color("141d3a"))
	c.gradient_box(Rect2(LAB_X - 6, CEILING_Y, 12, FLOOR_Y - CEILING_Y), 2.5, MET, MET_D)


func _circuit_path(i: int) -> PackedVector2Array:
	var y := 78.0 + i * 34.0
	var bend := LAB_X + 30.0 + i * 17.0
	return PackedVector2Array([
		Vector2(LAB_X + 6, y), Vector2(bend, y), Vector2(bend + 14, y + 14), Vector2(ROOM_SIZE.x, y + 14),
	])


func _paint_circuits(c: VectorCanvas, t: float) -> void:
	for i in 6:
		var path := _circuit_path(i)
		c.draw_polyline(path, Color(CYAN_D, 0.7), 1.2, true)
		c.draw_circle(path[1], 1.6, CYAN_D)
		# Pulso de datos que recorre el circuito.
		var total := 0.0
		for k in path.size() - 1:
			total += path[k].distance_to(path[k + 1])
		var target := fmod(t * 60.0 + i * 47.0, total)
		for k in path.size() - 1:
			var length := path[k].distance_to(path[k + 1])
			if target <= length:
				var point := path[k].lerp(path[k + 1], target / length)
				c.glow(point, 5.0, Color(CYAN, 0.6), 5)
				c.draw_circle(point, 1.0, CYAN)
				break
			target -= length


func _paint_ceiling(c: VectorCanvas, t: float) -> void:
	c.gradient_rect(Rect2(0, 0, ROOM_SIZE.x, CEILING_Y), N0, N1)
	c.gradient_box(Rect2(-4, CEILING_Y - 6, ROOM_SIZE.x + 8, 7), 2.0, MET_L, MET_D)
	var cables := [[CYAN_D, 4.0], [MAG_D, 6.0], [LED_A.darkened(0.5), 8.0]]
	var x := 0.0
	while x < ROOM_SIZE.x:
		c.draw_rect(Rect2(x - 1.5, CEILING_Y, 3, 6), MET_D)
		for cable: Array in cables:
			c.draw_polyline(VectorCanvas.sag_curve(Vector2(x, CEILING_Y + 5), Vector2(x + HANGER_SPACING, CEILING_Y + 5), cable[1]),
				cable[0], 1.3, true)
		x += HANGER_SPACING
	# Paquetes de datos viajando por el cable cian; se infectan al llegar al laboratorio.
	for i in 7:
		var px := fmod(t * 70.0 + i * 140.0, ROOM_SIZE.x + 16.0) - 8.0
		var u := fmod(px, HANGER_SPACING) / HANGER_SPACING
		var point := Vector2(px, CEILING_Y + 5 + 4.0 * 4.0 * u * (1.0 - u) * 1.0)
		var color := MAG if px > CORRUPTION.position.x - 40.0 else CYAN
		c.glow(point, 5.0, Color(color, 0.55), 5)
		c.draw_colored_polygon(VectorCanvas.rounded_rect(Rect2(point - Vector2(2.5, 1.2), Vector2(5, 2.4)), 1.2), color)


func _paint_corridor_decor(c: VectorCanvas, t: float) -> void:
	# Lámparas.
	for x in range(40, int(LAB_X), 128):
		c.gradient_box(Rect2(x, CEILING_Y, 22, 4), 1.5, MET, MET_D)
		c.draw_colored_polygon(VectorCanvas.rounded_rect(Rect2(x + 2, CEILING_Y + 3.5, 18, 2.5), 1.2), Color("fff3d6"))
		c.glow(Vector2(x + 11, CEILING_Y + 5), 14.0, Color(1, 0.9, 0.7, 0.35))
	_paint_pennants(c, Vector2(28, 140), 72.0, t)
	_paint_pennants(c, Vector2(420, 140), 72.0, t)
	_paint_clock(c, Vector2(260, 126), t)
	_paint_board(c, Vector2(120, 232))
	_paint_window(c, Vector2(172, 196))
	_paint_window(c, Vector2(284, 196))
	_paint_door(c, Vector2(232, FLOOR_Y - 48), Color.WHITE)
	_paint_holo_sign(c, Rect2(232, 238, 30, 13), "SALA 3", t)
	_paint_router(c, Vector2(344, 150), t)


func _paint_pennants(c: VectorCanvas, start: Vector2, width: float, t: float) -> void:
	var rope := VectorCanvas.sag_curve(start, start + Vector2(width, 0), 3.0, 18)
	c.draw_polyline(rope, PAPER_D, 0.8, true)
	var colors: Array[Color] = [CYAN_M, HOOD, TEAL_L, MAG_D, LED_A]
	for i in 9:
		var p := rope[i * 2]
		var sway := sin(t * 1.5 + i) * 0.6
		var flag := PackedVector2Array([p + Vector2(0, 0.5), p + Vector2(6, 0.5), p + Vector2(3 + sway, 7)])
		c.shape(flag, colors[i % colors.size()], OUTLINE, 0.5)


func _paint_clock(c: VectorCanvas, center: Vector2, t: float) -> void:
	c.draw_circle(center, 7.5, OUTLINE)
	c.draw_circle(center, 6.5, PAPER)
	for i in 12:
		var dir := Vector2.from_angle(i * TAU / 12.0)
		c.draw_line(center + dir * 5.0, center + dir * 5.8, OUTLINE, 0.5, true)
	c.draw_line(center, center + Vector2.from_angle(t * 0.4 - PI / 2.0) * 5.0, OUTLINE, 0.6, true)
	c.draw_line(center, center + Vector2.from_angle(t * 0.03 - PI / 3.0) * 3.4, OUTLINE, 0.9, true)
	c.draw_circle(center, 0.8, Color("a8384a"))


func _paint_board(c: VectorCanvas, pos: Vector2) -> void:
	c.gradient_box(Rect2(pos, Vector2(36, 24)), 2.0, WOOD, WOOD_D)
	c.gradient_box(Rect2(pos + Vector2(2.5, 2.5), Vector2(31, 19)), 1.0, CORK, CORK.darkened(0.25), OUTLINE, 0.5)
	c.draw_set_transform(pos + Vector2(9, 8), -0.12)
	c.shape(VectorCanvas.rounded_rect(Rect2(-4, -3.5, 8, 7), 0.6), PAPER, OUTLINE, 0.4)
	for row in 2:
		c.draw_line(Vector2(-3, -1 + row * 2), Vector2(3, -1 + row * 2), PAPER_D, 0.5)
	c.draw_set_transform(pos + Vector2(17, 14), 0.1)
	c.shape(VectorCanvas.rounded_rect(Rect2(-3.5, -4, 7, 8), 0.6), PAPER_D, OUTLINE, 0.4)
	c.draw_set_transform(Vector2.ZERO)
	# Afiche: "¡Cuidado con el phishing!"
	c.gradient_box(Rect2(pos + Vector2(23, 4), Vector2(8, 12)), 1.0, MAG, MAG_D, OUTLINE, 0.5)
	c.draw_line(pos + Vector2(27, 6.5), pos + Vector2(27, 11), PAPER, 1.4, true)
	c.draw_circle(pos + Vector2(27, 13.3), 0.8, PAPER)
	c.draw_circle(pos + Vector2(9, 5), 0.8, Color("a8384a"))


func _paint_window(c: VectorCanvas, pos: Vector2) -> void:
	var rect := Rect2(pos, Vector2(40, 28))
	c.gradient_box(rect, 2.0, MET, MET_D)
	var glass := Rect2(pos + Vector2(2, 2), Vector2(36, 23))
	c.gradient_rect(glass, Color("0a0f22"), Color("1a2650"))
	c.draw_circle(pos + Vector2(30, 7), 2.5, Color(PAPER, 0.9))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x)
	var x := glass.position.x
	while x < glass.end.x - 2:
		var w := rng.randf_range(4, 8)
		var h := rng.randf_range(5, 13)
		var building := Rect2(x, glass.end.y - h, minf(w, glass.end.x - x), h)
		c.draw_rect(building, N3 if rng.randf() < 0.5 else N2)
		for k in 2:
			c.draw_rect(Rect2(building.position + Vector2(rng.randf_range(1, w - 2), rng.randf_range(1, h - 2)), Vector2(1, 1)),
				LED_A if k == 0 else CYAN_M)
		x += w
	c.draw_line(pos + Vector2(6, 22), pos + Vector2(16, 4), Color(1, 1, 1, 0.12), 2.5, true)
	c.draw_rect(Rect2(pos.x + 19.25, pos.y + 2, 1.5, 23), MET_D)
	c.gradient_box(Rect2(pos + Vector2(-1, 25), Vector2(42, 3)), 1.0, MET_L, MET)


func _paint_door(c: VectorCanvas, pos: Vector2, tint: Color) -> void:
	c.gradient_box(Rect2(pos, Vector2(28, 48)), 1.5, WOOD_D * tint, WOOD_D.darkened(0.3) * tint)
	c.gradient_box(Rect2(pos + Vector2(3.5, 3.5), Vector2(21, 44.5)), 1.0, WOOD_L * tint, WOOD * tint, OUTLINE, 0.5)
	c.gradient_box(Rect2(pos + Vector2(7, 8), Vector2(14, 12)), 1.0, CYAN_M, CYAN_D, OUTLINE, 0.7)
	c.draw_line(pos + Vector2(10, 18), pos + Vector2(15, 10), Color(CYAN, 0.8), 1.0, true)
	c.draw_circle(pos + Vector2(21, 29), 1.3, OUTLINE)
	c.draw_circle(pos + Vector2(21, 29), 0.9, MET_L)


func _paint_holo_sign(c: VectorCanvas, rect: Rect2, text: String, t: float) -> void:
	var flicker := 0.55 if fmod(t * 7.3 + rect.position.x, 11.0) < 0.35 else 1.0
	c.glow(rect.get_center(), rect.size.x * 0.7, Color(CYAN, 0.12 * flicker))
	c.draw_colored_polygon(VectorCanvas.rounded_rect(rect, 2.0), Color(CYAN_D, 0.5 * flicker))
	var border := VectorCanvas.rounded_rect(rect, 2.0)
	border.append(border[0])
	c.draw_polyline(border, Color(CYAN, 0.9 * flicker), 0.8, true)
	for y in range(int(rect.position.y) + 2, int(rect.end.y), 2):
		c.draw_line(Vector2(rect.position.x + 1, y), Vector2(rect.end.x - 1, y), Color(CYAN_D, 0.3), 0.5)
	c.crisp_text(Vector2(rect.position.x, rect.end.y - 3.5), text, 8, Color(CYAN, flicker), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)


func _paint_router(c: VectorCanvas, pos: Vector2, t: float) -> void:
	var center := pos + Vector2(9, 2)
	for i in 3:
		var pulse := fmod(t * 0.9 - i * 0.33, 1.0)
		c.draw_arc(center, 6.0 + i * 5.0, PI * 1.2, PI * 1.8, 12, Color(CYAN, 0.25 + 0.75 * (1.0 - pulse)), 1.2, true)
	c.draw_line(pos + Vector2(4, 0), pos + Vector2(4, 7), MET_L, 1.0, true)
	c.draw_line(pos + Vector2(14, 0), pos + Vector2(14, 7), MET_L, 1.0, true)
	c.draw_circle(pos + Vector2(4, 0), 1.0, CYAN)
	c.draw_circle(pos + Vector2(14, 0), 1.0, CYAN)
	c.gradient_box(Rect2(pos + Vector2(1, 6), Vector2(16, 6)), 1.5, MET, MET_D)
	for i in 4:
		c.draw_circle(pos + Vector2(5 + i * 2.5, 9), 0.6, LED_G if i < 3 else CYAN)


func _paint_lockers(c: VectorCanvas, _t: float) -> void:
	for group: Array in [[24.0, 5, 3], [376.0, 4, 1]]:
		for i: int in group[1]:
			var x: float = group[0] + i * 16.0
			c.gradient_box(Rect2(x + 0.5, FLOOR_Y - 40, 15, 40), 1.5, TEAL_L, TEAL_D)
			for row in 3:
				c.draw_line(Vector2(x + 4.5, FLOOR_Y - 36 + row * 2.2), Vector2(x + 11.5, FLOOR_Y - 36 + row * 2.2), TEAL_D, 1.0, true)
			c.shape(VectorCanvas.rounded_rect(Rect2(x + 5, FLOOR_Y - 28, 5, 3), 0.6), PAPER_D, OUTLINE, 0.4)
			c.draw_line(Vector2(x + 11.5, FLOOR_Y - 21), Vector2(x + 11.5, FLOOR_Y - 17), MET_L, 1.0, true)
			if i == group[2]:
				c.draw_circle(Vector2(x + 6, FLOOR_Y - 13), 2.2, MAG_D)
				c.draw_circle(Vector2(x + 6, FLOOR_Y - 13), 1.2, MAG)
				c.draw_colored_polygon(VectorCanvas.rounded_rect(Rect2(x + 9, FLOOR_Y - 12, 3, 3), 0.8), CYAN_M)


func _paint_trays(c: VectorCanvas, _t: float) -> void:
	for rect in ONE_WAY_PLATFORMS:
		for k in 2:
			c.draw_polyline(VectorCanvas.sag_curve(rect.position + Vector2(2, 4), Vector2(rect.end.x - 2, rect.position.y + 4), 5.0 + k * 3.0),
				[CYAN_D, MAG_D][k], 1.2, true)
		c.gradient_box(Rect2(rect.position - Vector2(0, 1), Vector2(rect.size.x, 5)), 2.0, MET_L, MET_D)
		c.draw_circle(rect.position + Vector2(6, 1.5), 0.7, LED_G)


func _paint_lab(c: VectorCanvas, t: float) -> void:
	for i in 2:
		var x := 700.0 + i * 30.0
		# Canaleta: los cables del techo bajan hasta el servidor.
		var conduit := Rect2(x + 10.5, CEILING_Y, 7, FLOOR_Y - 64 - CEILING_Y)
		c.draw_polygon(
			PackedVector2Array([conduit.position, Vector2(conduit.end.x, conduit.position.y), conduit.end, Vector2(conduit.position.x, conduit.end.y)]),
			PackedColorArray([MET, MET_D, MET_D, MET]))
		c.draw_line(Vector2(x + 13, CEILING_Y), Vector2(x + 13, conduit.end.y), CYAN_D, 0.8)
		c.draw_line(Vector2(x + 15, CEILING_Y), Vector2(x + 15, conduit.end.y), MAG_D, 0.8)
		# Rack de servidores con luces que parpadean.
		var rack := Rect2(x, FLOOR_Y - 64, 28, 64)
		c.gradient_box(rack, 2.5, MET, MET_D)
		c.draw_colored_polygon(VectorCanvas.rounded_rect(rack.grow(-3), 1.5), N0)
		for u in 7:
			var unit := Rect2(x + 4, rack.position.y + 4 + u * 8, 20, 6)
			c.gradient_box(unit, 1.2, MET_L, MET, OUTLINE, 0.4)
			for led in 3:
				var on := hash(Vector3i(i, u * 3 + led, int(t * (3 + i)))) % 4 != 0
				var color := LED_G if led < 2 else LED_A
				if u == 5 and led == 2 and int(t * 2) % 2 == 0:
					color = LED_R
				if on:
					c.glow(unit.position + Vector2(13 + led * 2.6, 3), 2.5, Color(color, 0.6), 3)
					c.draw_circle(unit.position + Vector2(13 + led * 2.6, 3), 0.7, color)
	# Puerta corrediza de vidrio del laboratorio.
	var door := Rect2(780, FLOOR_Y - 48, 30, 48)
	c.gradient_box(door, 1.5, CYAN_D, N1, OUTLINE, 0.8)
	c.gradient_box(door.grow(-2.5), 1.0, Color(CYAN_M, 0.35), Color(N2, 0.6), Color(CYAN, 0.6), 0.6)
	c.draw_line(Vector2(door.get_center().x, door.position.y + 2), Vector2(door.get_center().x, door.end.y), Color(CYAN, 0.5), 0.8)
	c.draw_line(door.position + Vector2(6, 40), door.position + Vector2(12, 8), Color(1, 1, 1, 0.15), 2.0, true)
	c.gradient_box(Rect2(door.end.x + 3, door.position.y + 18, 5, 8), 1.0, MET, MET_D, OUTLINE, 0.5)
	c.draw_circle(Vector2(door.end.x + 5.5, door.position.y + 20.5), 0.8, LED_G)
	_paint_holo_sign(c, Rect2(758, 106, 58, 14), "LABORATORIO", t)


func _paint_floor(c: VectorCanvas, _t: float) -> void:
	c.gradient_rect(Rect2(0, FLOOR_Y, ROOM_SIZE.x, 5), N5, N4)
	c.draw_line(Vector2(0, FLOOR_Y), Vector2(ROOM_SIZE.x, FLOOR_Y), Color(CYAN, 0.35), 0.8)
	c.draw_line(Vector2(0, FLOOR_Y + 5), Vector2(ROOM_SIZE.x, FLOOR_Y + 5), OUTLINE, 1.0)
	c.gradient_rect(Rect2(0, FLOOR_Y + 5.5, ROOM_SIZE.x, 60), N2, N0)
	# Reflejos de las lámparas en el suelo pulido.
	for x in range(40, int(LAB_X), 128):
		c.draw_set_transform(Vector2(x + 11, FLOOR_Y + 2.5), 0.0, Vector2(3.0, 0.25))
		c.glow(Vector2.ZERO, 10.0, Color(1, 0.9, 0.7, 0.35), 5)
	c.draw_set_transform(Vector2.ZERO)


func _paint_corruption(c: VectorCanvas, t: float) -> void:
	var area := CORRUPTION
	var base := Vector2(area.get_center().x, FLOOR_Y)
	for i in 5:
		var offset := Vector2(sin(t * 1.3 + i * 1.7) * 18.0, 0)
		var radius := 6.0 + sin(t * 2.0 + i) * 2.0
		c.draw_set_transform(base + offset, 0.0, Vector2(1.6, 0.35))
		c.glow(Vector2.ZERO, radius * 2.0, Color(MAG, 0.35), 5)
	c.draw_set_transform(Vector2.ZERO)
	# Grietas en el suelo y fragmentos de "fallo".
	c.draw_polyline(PackedVector2Array([base + Vector2(-26, 1), base + Vector2(-12, 3), base + Vector2(-4, 1.5), base + Vector2(8, 4), base + Vector2(24, 2)]),
		MAG, 0.8, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t * 10.0)
	for i in 6:
		var p := base + Vector2(rng.randf_range(-30, 30), rng.randf_range(-14, 3))
		c.draw_rect(Rect2(p, Vector2(rng.randf_range(2, 6), 1.2)), MAG if i % 2 == 0 else CYAN)


func _paint_lure(c: VectorCanvas, t: float) -> void:
	var pos := LURE_POSITION + Vector2(0, sin(t * 2.0) * 2.0)
	c.draw_line(Vector2(pos.x, CEILING_Y), pos + Vector2(0, -15), MET_L, 0.6, true)
	# Anzuelo.
	c.draw_line(pos + Vector2(0, -15), pos + Vector2(0, -8), MET_L, 1.1, true)
	c.draw_arc(pos + Vector2(-2.2, -8), 2.2, 0.0, PI, 10, MET_L, 1.1, true)
	c.draw_line(pos + Vector2(-4.4, -8), pos + Vector2(-3.6, -10), MET_L, 1.0, true)
	# Tentáculos de corrupción.
	for i in 3:
		var root := pos + Vector2(-6 + i * 6, 6)
		var points := PackedVector2Array()
		for k in 7:
			points.append(root + Vector2(sin(t * 3.0 + i * 2.0 + k * 0.7) * 1.6, k * 1.6))
		for k in points.size() - 1:
			c.draw_line(points[k], points[k + 1], Color(MAG, 1.0 - k / 7.0), lerpf(1.6, 0.4, k / 6.0), true)
	# Sobre.
	var envelope := Rect2(pos + Vector2(-9, -6), Vector2(18, 12))
	c.gradient_box(envelope, 1.5, PAPER, PAPER_D)
	c.draw_polyline(PackedVector2Array([envelope.position + Vector2(0.5, 0.5), envelope.get_center() + Vector2(0, 0.5), Vector2(envelope.end.x - 0.5, envelope.position.y + 0.5)]),
		PAPER_D.darkened(0.2), 0.8, true)
	c.glow(envelope.get_center() + Vector2(0, 0.5), 6.0, Color(MAG, 0.5), 5)
	c.draw_circle(envelope.get_center() + Vector2(0, 0.5), 1.8, MAG)
	var blink := 0.3 if fmod(t, 3.0) < 0.12 else 1.0
	for side in [-1, 1]:
		var eye := envelope.get_center() + Vector2(side * 4.5, 3.2)
		c.draw_line(eye - Vector2(1.2, 0), eye + Vector2(1.2, 0), Color(MAG, blink), 1.0, true)
	# Fallo visual intermitente: franjas desplazadas.
	if int(t * 6.0) % 5 == 0:
		c.draw_rect(Rect2(envelope.position + Vector2(3, 3), Vector2(18, 2)), Color(PAPER, 0.85))
		c.draw_rect(Rect2(envelope.position + Vector2(-2, 7), Vector2(14, 1)), Color(CYAN, 0.8))
		c.draw_rect(Rect2(envelope.position + Vector2(5, 4.5), Vector2(10, 1)), Color(MAG, 0.9))
