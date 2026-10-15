class_name KeepsakeArt
extends RefCounted
## Dibujos provisionales (por código) de los objetos del cuarto de Kai, hasta que Ariel los dibuje: el
## mismo dibujo sirve chiquito en la estantería y grande en la ventana de inspección. Cada uno se
## dibuja dentro de rect (proporción cuadrada). Si el Keepsake tiene texture, se usa esa.

const OUTLINE := Color("1a1424")


static func draw(canvas: CanvasItem, item: Keepsake, rect: Rect2, time := 0.0) -> void:
	if item.texture:
		canvas.draw_texture_rect(item.texture, _fit(rect, item.texture.get_size()), false)
		return
	draw_art(canvas, item.art, rect, time)


static func draw_art(canvas: CanvasItem, art: StringName, rect: Rect2, time := 0.0) -> void:
	var u := rect.size.x / 16.0  # Una «celda» del dibujo (16 × 16).
	var o := rect.position
	match art:
		&"robot":
			_box(canvas, o, u, Rect2(5, 2, 6, 5), Color("9aa6b8"))  # Cabeza
			_box(canvas, o, u, Rect2(7.5, 0.5, 1, 1.5), Color("c0c8d8"))  # Antena
			canvas.draw_circle(o + Vector2(8, 0.6) * u, u * 0.6, Color("ff6a6a"))
			_box(canvas, o, u, Rect2(6, 3.5, 1.4, 1.4), Color("3ef2ff"))  # Ojos
			_box(canvas, o, u, Rect2(8.6, 3.5, 1.4, 1.4), Color("3ef2ff"))
			_box(canvas, o, u, Rect2(4, 7, 8, 6), Color("7a8698"))  # Cuerpo
			_box(canvas, o, u, Rect2(6, 8.5, 4, 2), Color("f2c14e"))  # Pegatina casi borrada
			_box(canvas, o, u, Rect2(2.5, 7.5, 1.5, 4), Color("9aa6b8"))  # Brazos
			_box(canvas, o, u, Rect2(12, 7.5, 1.5, 4), Color("9aa6b8"))
			canvas.draw_circle(o + Vector2(5.5, 14) * u, u * 1.5, OUTLINE)  # Ruedas (la derecha, dañada)
			canvas.draw_circle(o + Vector2(10.5, 14) * u, u * 1.5, OUTLINE)
			canvas.draw_line(o + Vector2(9.6, 13) * u, o + Vector2(11.4, 15) * u, Color("c0c8d8"), maxf(u * 0.4, 1.0))
		&"foto_familia":
			_frame(canvas, o, u, Color("c89a5a"), Color("f6d8a8"))
			_person(canvas, o, u, 5.0, 8.5, Color("6a4a8a"), Color("3a2418"), 1.0)  # Mamá
			_person(canvas, o, u, 11.0, 8.0, Color("3a6c8a"), Color("2a1a10"), 1.05)  # Papá
			_person(canvas, o, u, 8.0, 10.5, Color("3ef2ff"), Color("e8e8f0"), 0.7)  # Kai chiquito
		&"foto_escuela":
			_frame(canvas, o, u, Color("8a8fa8"), Color("bfe0f2"))
			for k in 4:
				_person(canvas, o, u, 3.5 + k * 3.0, 9.5 + (k % 2) * 0.6, [Color("c0504d"), Color("3ef2ff"), Color("9bbb59"), Color("8064a2")][k], Color("2a1a10"), 0.75)
			_box(canvas, o, u, Rect2(3, 2.5, 10, 1.5), Color("1f6f5a"))  # Cartel del grupo
		&"pulsera":
			for k in 9:
				var angle := TAU * k / 9.0
				canvas.draw_circle(o + (Vector2(8, 8) + Vector2(cos(angle), sin(angle)) * 4.5) * u, u * 1.2,
					[Color("f2c14e"), Color("3ef2ff"), Color("ff6ab4")][k % 3])
		&"kit_electronica":
			_box(canvas, o, u, Rect2(2, 5, 12, 8), Color("2f6f5a"))  # Placa
			for k in 4:
				_box(canvas, o, u, Rect2(3.5 + k * 2.6, 6.5, 1.6, 1.6), Color("d8c060"))
			_box(canvas, o, u, Rect2(4, 9.5, 4, 2), OUTLINE)  # Chip
			canvas.draw_circle(o + Vector2(11, 10.5) * u, u * 1.1, Color("ff4a6a"))  # LED
			_box(canvas, o, u, Rect2(1, 3, 14, 1.2), Color("c0504d"))  # Moño del regalo
			_box(canvas, o, u, Rect2(7.4, 1, 1.2, 4), Color("c0504d"))
		&"dibujo_hermanos":
			_box(canvas, o, u, Rect2(2, 1, 12, 14), Color("f4f0e4"))  # Hoja del cuaderno
			for k in 6:
				canvas.draw_line(o + Vector2(2, 3 + k * 2.2) * u, o + Vector2(14, 3 + k * 2.2) * u, Color("9bd0e8"), maxf(u * 0.12, 1.0))
			canvas.draw_circle(o + Vector2(6, 8) * u, u * 2.2, Color("ff6a8a"))  # Chip y Glitch dibujados con lapicero
			canvas.draw_circle(o + Vector2(10.5, 8.5) * u, u * 2.0, Color("6a9aff"))
			_box(canvas, o, u, Rect2(5, 7.5, 0.8, 0.8), OUTLINE)
			_box(canvas, o, u, Rect2(9.8, 8, 0.8, 0.8), OUTLINE)
			_box(canvas, o, u, Rect2(4, 12, 8, 0.6), Color("4f81bd"))  # «¿Qué son?»
		&"fragmento", &"fragmento_rojo":
			var main := Color("b9a6ff") if art == &"fragmento" else Color("ff6a8a")
			var glow := 0.5 + 0.5 * sin(time * 2.5)
			canvas.draw_circle(o + Vector2(8, 8) * u, u * (5.5 + glow), Color(main, 0.18))
			var points := PackedVector2Array([Vector2(8, 1.5), Vector2(12, 7), Vector2(9, 14.5), Vector2(5, 9)])
			for i in points.size():
				points[i] = o + points[i] * u
			canvas.draw_colored_polygon(points, main)
			canvas.draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, maxf(u * 0.25, 1.0))
			canvas.draw_line(o + Vector2(8, 1.5) * u, o + Vector2(9, 14.5) * u, Color(1, 1, 1, 0.5), maxf(u * 0.2, 1.0))
		&"reloj":
			_box(canvas, o, u, Rect2(6, 0.5, 4, 15), Color("5a4030"))  # Correa
			canvas.draw_circle(o + Vector2(8, 8) * u, u * 4.2, Color("c8a050"))
			canvas.draw_circle(o + Vector2(8, 8) * u, u * 3.4, Color("f4f0e4"))
			canvas.draw_line(o + Vector2(8, 8) * u, o + Vector2(8, 5.4) * u, OUTLINE, maxf(u * 0.35, 1.0))
			canvas.draw_line(o + Vector2(8, 8) * u, o + Vector2(10, 8.6) * u, OUTLINE, maxf(u * 0.25, 1.0))
		&"nota":
			_box(canvas, o, u, Rect2(3, 2, 10, 12), Color("fff8e0"))  # Papel
			for k in 4:
				canvas.draw_line(o + Vector2(4.5, 5 + k * 2.2) * u, o + Vector2(11.5 - (k % 2) * 2.0, 5 + k * 2.2) * u, Color("4f81bd"), maxf(u * 0.25, 1.0))
			canvas.draw_circle(o + Vector2(11, 13.5) * u, u * 1.4, Color("ff6a8a"))  # Corazón (dibujito)
			_box(canvas, o, u, Rect2(6.5, 0.5, 3, 2), Color(1.0, 0.95, 0.6, 0.8))  # Cinta
		&"bloqueado":
			canvas.draw_rect(rect.grow(-u), Color(1, 1, 1, 0.06))
			canvas.draw_rect(rect.grow(-u), Color(1, 1, 1, 0.25), false, maxf(u * 0.2, 1.0))
			canvas.draw_string(ThemeDB.fallback_font, o + Vector2(4.6, 11) * u, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(u * 9.0), Color(1, 1, 1, 0.35))
		_:
			_box(canvas, o, u, Rect2(3, 3, 10, 10), Color("8a8fa8"))


static func _box(canvas: CanvasItem, o: Vector2, u: float, cells: Rect2, color: Color) -> void:
	var rect := Rect2(o + cells.position * u, cells.size * u)
	canvas.draw_rect(rect, color)
	canvas.draw_rect(rect, OUTLINE, false, maxf(u * 0.15, 1.0))


static func _frame(canvas: CanvasItem, o: Vector2, u: float, wood: Color, inside: Color) -> void:
	canvas.draw_rect(Rect2(o + Vector2(1, 1) * u, Vector2(14, 14) * u), wood)
	canvas.draw_rect(Rect2(o + Vector2(2.4, 2.4) * u, Vector2(11.2, 11.2) * u), inside)
	canvas.draw_rect(Rect2(o + Vector2(1, 1) * u, Vector2(14, 14) * u), OUTLINE, false, maxf(u * 0.15, 1.0))


## Una personita (cabeza, pelo y cuerpo) parada con los pies en y = 13.
static func _person(canvas: CanvasItem, o: Vector2, u: float, x: float, head_y: float, shirt: Color, hair: Color, size: float) -> void:
	var h := 2.2 * size
	canvas.draw_rect(Rect2(o + Vector2(x - 1.6 * size, head_y + h * 0.8) * u, Vector2(3.2 * size, 13.0 - head_y - h * 0.8) * u), shirt)
	canvas.draw_circle(o + Vector2(x, head_y) * u, u * h * 0.75, Color("e0b090"))
	canvas.draw_rect(Rect2(o + Vector2(x - h * 0.75, head_y - h * 0.8) * u, Vector2(h * 1.5, h * 0.6) * u), hair)


static func _fit(rect: Rect2, size: Vector2) -> Rect2:
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var fitted := size * scale
	return Rect2(rect.position + (rect.size - fitted) / 2.0, fitted)
