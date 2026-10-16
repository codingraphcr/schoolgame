extends SceneTree
## Animación del Grimorio abriéndose (hoja de Ariel: docs/arte/referencias/grimorio_hoja.webp, la fila de abajo):
## seis cuadros, de cerrado a abierto con la luz que sale de las páginas. La hoja tiene fondo blanco y una sombra
## violeta borrosa alrededor de cada libro: se borran desde los bordes del cuadro (relleno por lo que es blanco
## o liso, sin bordes marcados: la sombra borrosa; el libro de pixel art tiene bordes marcados y lo frena) y
## queda solo el libro (la mancha más grande). Sale una tira de cuadros iguales, con la base de los libros
## alineada: assets/art/items/grimorio/grimorio_abriendo.png (se dibuja a la mitad, como Kai).
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_grimorio_abriendo.gd

const SOURCE := "res://docs/arte/referencias/grimorio_hoja.webp"
const OUT := "res://assets/art/items/grimorio/grimorio_abriendo.png"
const FRAMES: Array[Rect2i] = [Rect2i(525, 655, 135, 177), Rect2i(685, 655, 137, 177), Rect2i(848, 655, 157, 177),
	Rect2i(1035, 655, 210, 177), Rect2i(1255, 655, 215, 177), Rect2i(1485, 655, 225, 177)]
## Escala de la hoja al cuadro (a la mitad en el mundo: el libro abierto mide unos 66 px).
const SCALE := 0.59
const CELL := Vector2i(136, 106)
## Diferencia con los vecinos por debajo de la cual un punto es «liso» (fondo o sombra borrosa).
const SMOOTH := 0.045
## Un punto casi blanco siempre es fondo.
const WHITE := 0.8


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	sheet.convert(Image.FORMAT_RGBA8)
	var strip := Image.create(CELL.x * FRAMES.size(), CELL.y, false, Image.FORMAT_RGBA8)
	for i in FRAMES.size():
		var cut := _cut(sheet.get_region(FRAMES[i]))
		var size := Vector2i(int(round(cut.get_width() * SCALE)), int(round(cut.get_height() * SCALE)))
		cut.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		# Centrado y con la base abajo.
		strip.blend_rect(cut, Rect2i(Vector2i.ZERO, size), Vector2i(i * CELL.x + (CELL.x - size.x) / 2, CELL.y - size.y))
	strip.save_png(ProjectSettings.globalize_path(OUT))
	print("%s (%d cuadros de %dx%d)" % [OUT, FRAMES.size(), CELL.x, CELL.y])
	quit()


func _cut(image: Image) -> Image:
	var size := image.get_size()
	var bg := PackedByteArray()
	bg.resize(size.x * size.y)
	var stack: Array[Vector2i] = []
	for x in size.x:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, size.y - 1))
	for y in size.y:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(size.x - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= size.x or p.y >= size.y or bg[p.y * size.x + p.x] == 1:
			continue
		var c := image.get_pixelv(p)
		var white := minf(minf(c.r, c.g), c.b) > WHITE
		if not white and _contrast(image, p) >= SMOOTH:
			continue
		bg[p.y * size.x + p.x] = 1
		stack.append(p + Vector2i.RIGHT)
		stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN)
		stack.append(p + Vector2i.UP)
	# Solo la mancha más grande (el libro): fuera los cuadraditos y rayos sueltos.
	var label := PackedInt32Array()
	label.resize(size.x * size.y)
	var best := 0
	var best_count := 0
	var next := 0
	for start in size.x * size.y:
		if bg[start] == 1 or label[start] != 0:
			continue
		next += 1
		var count := 0
		var queue: Array[int] = [start]
		label[start] = next
		while not queue.is_empty():
			var i: int = queue.pop_back()
			count += 1
			var x := i % size.x
			var y := i / size.x
			for n in [i - 1 if x > 0 else -1, i + 1 if x < size.x - 1 else -1, i - size.x if y > 0 else -1, i + size.x if y < size.y - 1 else -1]:
				if n >= 0 and bg[n] == 0 and label[n] == 0:
					label[n] = next
					queue.append(n)
		if count > best_count:
			best_count = count
			best = next
	var out := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			if label[y * size.x + x] == best:
				out.set_pixel(x, y, image.get_pixel(x, y))
	return out


## Cuánto cambia el color alrededor (a 2 px): alto en los bordes del pixel art, bajo en la sombra borrosa.
func _contrast(image: Image, p: Vector2i) -> float:
	var c := image.get_pixelv(p)
	var most := 0.0
	for d in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
		var q: Vector2i = (p + d).clamp(Vector2i.ZERO, image.get_size() - Vector2i.ONE)
		var o := image.get_pixelv(q)
		most = maxf(most, maxf(maxf(absf(c.r - o.r), absf(c.g - o.g)), absf(c.b - o.b)))
	return most
