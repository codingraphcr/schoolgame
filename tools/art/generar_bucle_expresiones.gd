extends SceneTree
## Expresiones del retrato de Bucle para los diálogos: sobre el retrato de Ariel (bucle_retrato.png, la cara
## feliz) borra los ojos y la boca y los redibuja con el mismo estilo (trazo amarillo en bloques de 5 px y un
## halo naranja-rojo): triste, preocupado y asustado. El anillo, la antena y las chispas quedan iguales.
## Ejecutar (después de extraer_retratos.gd):
##   godot --headless --path . --script res://tools/art/generar_bucle_expresiones.gd

const DIR := "res://assets/art/characters/bucle/"
const SOURCE := "bucle_retrato.png"
## La cara (el círculo oscuro dentro del anillo).
const FACE_CENTER := Vector2(305, 318)
const FACE_RADIUS := 114.0
## Zona de los ojos y la boca de la cara feliz (se borra).
const FEATURES := Rect2i(172, 272, 270, 116)
const BLOCK := 5
const CORE := Color(1.0, 0.93, 0.42)
const RIM := Color(1.0, 0.6, 0.14)
const HALO := Color(0.86, 0.2, 0.05)
const HALO_SIZE := 13.0
const LEFT_EYE := Vector2(231, 328)
const RIGHT_EYE := Vector2(379, 328)
const MOUTH := Vector2(305, 360)


func _initialize() -> void:
	var base := Image.load_from_file(ProjectSettings.globalize_path(DIR + SOURCE))
	base.convert(Image.FORMAT_RGBA8)
	var dark := base.get_pixel(300, 262)
	for expression: String in ["triste", "preocupado", "asustado"]:
		var image := base.duplicate() as Image
		_erase(image, dark)
		_paint(image, dark, Callable(self, "_" + expression))
		image.save_png(ProjectSettings.globalize_path(DIR + "bucle_retrato_%s.png" % expression))
		print("bucle_retrato_%s.png" % expression)
	quit()


func _erase(image: Image, _dark: Color) -> void:
	# La cara oscura tiene un degradado que se aclara hacia el anillo: cada punto toma el color del punto a la
	# misma distancia del centro, en una parte limpia de la cara (justo arriba del centro, sin ojos ni brillo).
	var source := image.duplicate() as Image
	var clean := Vector2(0, -1)
	for y in range(FEATURES.position.y, FEATURES.end.y):
		for x in range(FEATURES.position.x, FEATURES.end.x):
			var r := Vector2(x, y).distance_to(FACE_CENTER)
			if r >= FACE_RADIUS:
				continue
			var at := FACE_CENTER + clean * r
			# Se mezcla en los bordes (de la zona y cerca del anillo) para que no se note el corte.
			var edge := minf(minf(x - FEATURES.position.x, FEATURES.end.x - 1 - x), minf(y - FEATURES.position.y, FEATURES.end.y - 1 - y))
			var weight := clampf(edge / 10.0, 0.0, 1.0) * clampf((FACE_RADIUS - r) / 8.0, 0.0, 1.0)
			image.set_pixel(x, y, source.get_pixel(x, y).lerp(source.get_pixel(int(at.x), int(at.y)), weight))


## Pinta la expresión: shape(p) dice si el punto p es trazo. El trazo va en bloques de BLOCK px (como el
## dibujo de Ariel) y alrededor, un halo que se apaga.
func _paint(image: Image, dark: Color, shape: Callable) -> void:
	var core: Array[Vector2] = []
	for by in range(FEATURES.position.y - 20, FEATURES.end.y + 20, BLOCK):
		for bx in range(FEATURES.position.x - 20, FEATURES.end.x + 20, BLOCK):
			if shape.call(Vector2(bx + BLOCK * 0.5, by + BLOCK * 0.5)):
				core.append(Vector2(bx, by))
	var area := Rect2i(FEATURES.position - Vector2i(30, 30), FEATURES.size + Vector2i(60, 60))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(FACE_CENTER) >= FACE_RADIUS:
				continue
			var nearest := INF
			for block in core:
				var dx := maxf(maxf(block.x - p.x, p.x - (block.x + BLOCK)), 0.0)
				var dy := maxf(maxf(block.y - p.y, p.y - (block.y + BLOCK)), 0.0)
				nearest = minf(nearest, sqrt(dx * dx + dy * dy))
			if nearest == 0.0:
				image.set_pixel(x, y, CORE)
			elif nearest <= 2.0:
				image.set_pixel(x, y, RIM)
			elif nearest < HALO_SIZE:
				var glow := 1.0 - (nearest - 2.0) / (HALO_SIZE - 2.0)
				image.set_pixel(x, y, image.get_pixel(x, y).lerp(HALO, glow * glow * 0.9))


## --- Formas ---

func _triste(p: Vector2) -> bool:
	# Ojos redondos, cejas levantadas hacia el centro, boca hacia abajo y una lágrima.
	return _circle(p, LEFT_EYE, 17.0) or _circle(p, RIGHT_EYE, 17.0) \
		or _segment(p, LEFT_EYE + Vector2(-28, -24), LEFT_EYE + Vector2(18, -42), 5.0) \
		or _segment(p, RIGHT_EYE + Vector2(28, -24), RIGHT_EYE + Vector2(-18, -42), 5.0) \
		or _arc(p, MOUTH + Vector2(0, 22), 20.0, PI * 1.15, PI * 1.85, 4.5) \
		or _circle(p, LEFT_EYE + Vector2(-16, 32), 7.0) or _segment(p, LEFT_EYE + Vector2(-16, 22), LEFT_EYE + Vector2(-16, 30), 3.5)


func _preocupado(p: Vector2) -> bool:
	# Ojos redondos, cejas apenas levantadas al centro y una boca ondulada.
	var mouth := false
	var points := [Vector2(-27, 2), Vector2(-14, -6), Vector2(0, 2), Vector2(14, -6), Vector2(27, 2)]
	for i in points.size() - 1:
		mouth = mouth or _segment(p, MOUTH + points[i], MOUTH + points[i + 1], 4.5)
	return _circle(p, LEFT_EYE, 16.0) or _circle(p, RIGHT_EYE, 16.0) \
		or _segment(p, LEFT_EYE + Vector2(-26, -28), LEFT_EYE + Vector2(18, -38), 4.5) \
		or _segment(p, RIGHT_EYE + Vector2(26, -28), RIGHT_EYE + Vector2(-18, -38), 4.5) \
		or mouth


func _asustado(p: Vector2) -> bool:
	# Ojos grandes con la pupila oscura y la boca en «o».
	var eye := (_circle(p, LEFT_EYE, 22.0) and not _circle(p, LEFT_EYE, 9.0)) \
		or (_circle(p, RIGHT_EYE, 22.0) and not _circle(p, RIGHT_EYE, 9.0))
	return eye or _arc(p, MOUTH + Vector2(0, 4), 12.0, 0.0, TAU, 4.5)


func _circle(p: Vector2, c: Vector2, r: float) -> bool:
	return p.distance_to(c) <= r


func _segment(p: Vector2, a: Vector2, b: Vector2, half_width: float) -> bool:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t) <= half_width


func _arc(p: Vector2, c: Vector2, r: float, from: float, to: float, half_width: float) -> bool:
	var angle := fposmod((p - c).angle(), TAU)
	var inside := angle >= from and angle <= to if from <= to else (angle >= from or angle <= to)
	return inside and absf(p.distance_to(c) - r) <= half_width
