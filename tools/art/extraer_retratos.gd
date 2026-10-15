extends SceneTree
## Recorta los retratos para los diálogos (estilo Hades) de la hoja de diálogos de Ariel.
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_retratos.gd
##
## Los retratos grandes quedan con fondo transparente: se borra el fondo liso desde los bordes de
## arriba y de los costados (abajo no, porque ahí la ropa toca el borde) y después el halo oscuro
## que queda alrededor, y se pixelan (ver PIXEL_BLOCK). Las expresiones se recortan tal cual, con su fondo.

const SHEET := "res://docs/arte/referencias/dialogos_hoja_concepto.webp"
const KAI := "res://assets/art/characters/kai/retratos/"
const PROFESOR := "res://assets/art/characters/profesor/retratos/"

## Retratos grandes (fondo transparente): salida → zona dentro del marco.
const CUTOUTS := {
	KAI + "kai_retrato.png": Rect2i(6, 48, 348, 438),
	PROFESOR + "profesor_retrato.png": Rect2i(850, 48, 344, 440),
}
## Silueta del cuerpo (coordenadas dentro del recorte) que el borrado del fondo no puede atravesar:
## la ropa negra de Kai y el pelo del profesor detrás de la oreja son casi del color del fondo y,
## sin esto, se borraban por partes.
const KEEP := {
	KAI + "kai_retrato.png": [Vector2(95, 205), Vector2(150, 225), Vector2(240, 225), Vector2(300, 215),
		Vector2(348, 245), Vector2(348, 438), Vector2(40, 438), Vector2(48, 330), Vector2(60, 270), Vector2(95, 240)],
	PROFESOR + "profesor_retrato.png": [Vector2(240, 82), Vector2(262, 90), Vector2(285, 100), Vector2(298, 115),
		Vector2(300, 140), Vector2(296, 165), Vector2(285, 185), Vector2(270, 195), Vector2(255, 200), Vector2(240, 175), Vector2(238, 120)],
}
## Bolsillos de fondo encerrados entre mechones (no tocan el borde, así que el borrado desde los bordes
## no llega): se borran también desde estos puntos (coordenadas dentro del recorte).
const HOLES := {
	PROFESOR + "profesor_retrato.png": [Vector2i(53, 62)],
}
## Diferencia de color máxima con el fondo para borrarlo, y la más floja para el halo.
const TOLERANCE := 0.075
const HALO_TOLERANCE := 0.16
const HALO_PASSES := 2
## Pixelado (como el pixel art de Kai en el juego): bloques de PIXEL_BLOCK × PIXEL_BLOCK, paleta
## de PIXEL_COLORS colores y contorno oscuro. Las líneas oscuras (ojos, cejas, lentes) se conservan.
const PIXEL_BLOCK := 2
const PIXEL_COLORS := 32
const OUTLINE := Color("0a0d1c")

## Expresiones (primeros planos con fondo). No se usan como retrato porque cambian el encuadre;
## sirven de referencia para dibujarlas con el mismo encuadre que el retrato grande.
const EXPRESSIONS := {
	KAI: { "normal": Vector2i(374, 54), "serio": Vector2i(532, 54), "sorprendido": Vector2i(691, 54),
		"pensativo": Vector2i(374, 272), "preocupado": Vector2i(532, 272), "sonriente": Vector2i(691, 272) },
	PROFESOR: { "normal": Vector2i(1219, 84), "serio": Vector2i(1369, 84), "pensativo": Vector2i(1520, 84),
		"sorprendido": Vector2i(1219, 284), "preocupado": Vector2i(1369, 284), "sonriente": Vector2i(1520, 284) },
}
const EXPRESSION_SIZE := { KAI: Vector2i(134, 162), PROFESOR: Vector2i(127, 147) }


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	if sheet == null:
		push_error("No se encontró la hoja: " + SHEET)
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	for out: String in CUTOUTS:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		_pixelate(_cut_out(sheet.get_region(CUTOUTS[out]), PackedVector2Array(KEEP.get(out, [])), HOLES.get(out, []))).save_png(out)
		print(out.get_file())
	_extract_siblings()
	for dir: String in EXPRESSIONS:
		var prefix := "kai_" if dir == KAI else "profesor_"
		for expression: String in EXPRESSIONS[dir]:
			var out := dir + prefix + expression + ".png"
			sheet.get_region(Rect2i(EXPRESSIONS[dir][expression], EXPRESSION_SIZE[dir])).save_png(out)
			print(out.get_file())
	quit()


func _cut_out(image: Image, keep: PackedVector2Array, holes: Array = []) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var background := image.get_pixel(2, 2)
	var done := PackedByteArray()
	done.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
	for hole: Vector2i in holes:
		stack.append(hole)
	for y in int(h * 0.75):
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or done[p.y * w + p.x]:
			continue
		if _distance(image.get_pixelv(p), background) > TOLERANCE or _kept(p, keep):
			continue
		done[p.y * w + p.x] = 1
		image.set_pixelv(p, Color(0, 0, 0, 0))
		stack.append_array([p + Vector2i.RIGHT, p + Vector2i.LEFT, p + Vector2i.DOWN, p + Vector2i.UP])
	# Halo: píxeles parecidos al fondo que tocan lo transparente.
	for pass_index in HALO_PASSES:
		var halo: Array[Vector2i] = []
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var color := image.get_pixel(x, y)
				if color.a == 0.0 or _distance(color, background) > HALO_TOLERANCE or _kept(Vector2i(x, y), keep):
					continue
				if image.get_pixel(x + 1, y).a == 0.0 or image.get_pixel(x - 1, y).a == 0.0 \
						or image.get_pixel(x, y + 1).a == 0.0 or image.get_pixel(x, y - 1).a == 0.0:
					halo.append(Vector2i(x, y))
		for p in halo:
			image.set_pixelv(p, Color(0, 0, 0, 0))
	return image


func _distance(a: Color, b: Color) -> float:
	return (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0


func _kept(p: Vector2i, keep: PackedVector2Array) -> bool:
	return keep.size() >= 3 and Geometry2D.is_point_in_polygon(Vector2(p), keep)


## Pixela el retrato: lo reduce por bloques (conservando el trazo), limita la paleta, le pone un
## contorno oscuro y lo vuelve a agrandar sin suavizar (mismo tamaño que el original).
func _pixelate(image: Image) -> Image:
	var small := _downsample(image, PIXEL_BLOCK)
	var w := small.get_width()
	var h := small.get_height()
	var pixels: Array[Color] = []
	for y in h:
		for x in w:
			var c := small.get_pixel(x, y)
			if c.a > 0.0:
				pixels.append(c)
	var palette := _palette(pixels, PIXEL_COLORS)
	for y in h:
		for x in w:
			var c := small.get_pixel(x, y)
			if c.a > 0.0:
				small.set_pixel(x, y, _nearest(palette, c))
	var shape := small.duplicate() as Image
	for y in h:
		for x in w:
			if shape.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and shape.get_pixelv(q).a > 0.0:
					small.set_pixel(x, y, OUTLINE)
					break
	small.resize(w * PIXEL_BLOCK, h * PIXEL_BLOCK, Image.INTERPOLATE_NEAREST)
	return small


## Reduce por bloques: promedio del bloque, pero si tiene una línea oscura gana la línea. Alfa duro
## (o se ve o no se ve) y un poco más de contraste y color.
func _downsample(image: Image, block: int) -> Image:
	var w := image.get_width() / block
	var h := image.get_height() / block
	var small := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var sum := Vector3.ZERO
			var alpha := 0.0
			var count := 0
			var dark := Color.WHITE
			var dark_luminance := 2.0
			for j in block:
				for i in block:
					var c := image.get_pixel(x * block + i, y * block + j)
					alpha += c.a
					if c.a < 0.5:
						continue
					sum += Vector3(c.r, c.g, c.b)
					count += 1
					if c.get_luminance() < dark_luminance:
						dark_luminance = c.get_luminance()
						dark = c
			if count == 0 or alpha / (block * block) < 0.5:
				continue
			var avg := sum / count
			var color := Color(avg.x, avg.y, avg.z)
			if color.get_luminance() - dark_luminance > 0.18:
				color = color.lerp(dark, 0.75)
			color = Color((color.r - 0.5) * 1.1 + 0.5, (color.g - 0.5) * 1.1 + 0.5, (color.b - 0.5) * 1.1 + 0.5)
			color.s = minf(color.s * 1.1, 1.0)
			small.set_pixel(x, y, color)
	return small


## Paleta de "count" colores que mejor representa los píxeles (k-means sobre una muestra).
func _palette(pixels: Array[Color], count: int) -> Array[Color]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sample: Array[Color] = []
	for i in range(0, pixels.size(), maxi(pixels.size() / 6000, 1)):
		sample.append(pixels[i])
	var centers: Array[Color] = []
	for i in count:
		centers.append(sample[rng.randi_range(0, sample.size() - 1)])
	for iteration in 12:
		var sums: Array[Vector3] = []
		var counts: Array[int] = []
		sums.resize(count)
		counts.resize(count)
		sums.fill(Vector3.ZERO)
		counts.fill(0)
		for c in sample:
			var best := _nearest_index(centers, c)
			sums[best] += Vector3(c.r, c.g, c.b)
			counts[best] += 1
		for i in count:
			if counts[i] > 0:
				var mean := sums[i] / counts[i]
				centers[i] = Color(mean.x, mean.y, mean.z)
	return centers


func _nearest(palette: Array[Color], c: Color) -> Color:
	return palette[_nearest_index(palette, c)]


func _nearest_index(palette: Array[Color], c: Color) -> int:
	var best := 0
	var best_distance := INF
	for i in palette.size():
		var p := palette[i]
		# Distancia pesada como la percibe el ojo (el verde pesa más que el azul).
		var d := (c.r - p.r) ** 2 * 0.3 + (c.g - p.g) ** 2 * 0.59 + (c.b - p.b) ** 2 * 0.11
		if d < best_distance:
			best_distance = d
			best = i
	return best


## --- Glitch y Chip (hoja de diálogos de Ariel: dialogos_hermanos.webp) ---
## Su fondo no es liso (la sala con luces): se borra lo oscuro conectado con los bordes de arriba y de
## los costados (más oscuro que SIBLING_DARK) y se queda solo la figura más grande (el personaje con
## los efectos pegados: las llamas de Glitch, los hologramas de Chip). Después se pixelan igual.
const SIBLING_SHEET := "res://docs/arte/referencias/dialogos_hermanos.webp"
const SIBLINGS := "res://assets/art/characters/hermanos/retratos/"
const SIBLING_CUTOUTS := {
	SIBLINGS + "glitch_retrato.png": Rect2i(0, 0, 496, 466),
	SIBLINGS + "chip_retrato.png": Rect2i(0, 478, 496, 463),
}
const SIBLING_DARK := 0.4
## Silueta de cada uno (coordenadas dentro del recorte): adentro no se borra nada (el traje negro y el
## visor son casi del color del fondo y, sin esto, quedaban huecos transparentes).
const SIBLING_KEEP := {
	SIBLINGS + "glitch_retrato.png": [Vector2(30, 75), Vector2(110, 108), Vector2(150, 128), Vector2(230, 40), Vector2(290, 8),
		Vector2(332, 60), Vector2(352, 120), Vector2(420, 112), Vector2(472, 104), Vector2(452, 190), Vector2(432, 250),
		Vector2(442, 330), Vector2(432, 400), Vector2(486, 466), Vector2(0, 466), Vector2(0, 380), Vector2(60, 300),
		Vector2(88, 280), Vector2(94, 200), Vector2(58, 130)],
	SIBLINGS + "chip_retrato.png": [Vector2(175, 4), Vector2(226, 90), Vector2(290, 94), Vector2(446, 18), Vector2(432, 140),
		Vector2(426, 210), Vector2(442, 300), Vector2(420, 332), Vector2(402, 372), Vector2(424, 463), Vector2(20, 463),
		Vector2(20, 380), Vector2(150, 300), Vector2(114, 250), Vector2(118, 140), Vector2(150, 90)],
}


func _extract_siblings() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SIBLING_SHEET))
	if sheet == null:
		push_error("No se encontró la hoja: " + SIBLING_SHEET)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SIBLINGS))
	for out: String in SIBLING_CUTOUTS:
		var image := sheet.get_region(SIBLING_CUTOUTS[out])
		_cut_out_dark(image, PackedVector2Array(SIBLING_KEEP.get(out, [])))
		_keep_largest(image)
		_pixelate(image).save_png(out)
		print(out.get_file())


func _cut_out_dark(image: Image, keep: PackedVector2Array) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var done := PackedByteArray()
	done.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or done[p.y * w + p.x]:
			continue
		if image.get_pixelv(p).v > SIBLING_DARK or _kept(p, keep):
			continue
		done[p.y * w + p.x] = 1
		image.set_pixelv(p, Color(0, 0, 0, 0))
		stack.append_array([p + Vector2i.RIGHT, p + Vector2i.LEFT, p + Vector2i.DOWN, p + Vector2i.UP])


## Deja solo la figura conectada más grande (borra restos sueltos del fondo).
func _keep_largest(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	var best: Array[Vector2i] = []
	var current := 0
	for y in h:
		for x in w:
			if label[y * w + x] != 0 or image.get_pixel(x, y).a == 0.0:
				continue
			current += 1
			var component: Array[Vector2i] = []
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			label[y * w + x] = current
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				component.append(p)
				for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					var q := p + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or label[q.y * w + q.x] != 0 or image.get_pixelv(q).a == 0.0:
						continue
					label[q.y * w + q.x] = current
					stack.append(q)
			if component.size() > best.size():
				best = component
	var keep := PackedByteArray()
	keep.resize(w * h)
	for p in best:
		keep[p.y * w + p.x] = 1
	for y in h:
		for x in w:
			if keep[y * w + x] == 0:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
