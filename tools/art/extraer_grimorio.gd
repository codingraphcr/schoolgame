extends SceneTree
## Recorta el Grimorio del diseño de Ariel (docs/arte/referencias/grimorio_diseno.webp) con fondo transparente:
## borra el fondo oscuro desde los bordes (relleno: no entra en la tapa, que es oscura pero está rodeada por los
## bordes de metal y el brillo), se queda solo con el libro (descarta los cuadraditos sueltos de alrededor) y
## deja un halo violeta suave que se apaga. Salen dos tamaños:
##   grimorio_arte.png  (256 px de alto: la tarjeta «GRIMORIO»)
##   grimorio_libro.png (64 px de alto: el libro en el mundo, se dibuja a la mitad como Kai)
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_grimorio.gd

const SOURCE := "res://docs/arte/referencias/grimorio_diseno.webp"
const OUT := "res://assets/art/items/grimorio/"
## Diferencia con el fondo por debajo de la cual un punto es fondo (para el relleno desde los bordes).
const BACKGROUND := 0.30
## Hasta qué diferencia el halo se va volviendo opaco.
const GLOW := 0.6
## Silueta del libro en el diseño (con la cinta), marcada a mano: lo de afuera (el brillo y los cuadraditos
## pegados) se borra. Se agranda MARGIN px para no cortar el borde de metal.
var outline := PackedVector2Array([Vector2(336, 189), Vector2(471, 151), Vector2(543, 160), Vector2(1021, 289),
	Vector2(1036, 320), Vector2(1003, 870), Vector2(954, 977), Vector2(814, 1041), Vector2(493, 977), Vector2(486, 1070),
	Vector2(414, 1063), Vector2(414, 963), Vector2(279, 913), Vector2(236, 841), Vector2(257, 670), Vector2(286, 477),
	Vector2(321, 320)])
const MARGIN := 10.0


func _initialize() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	image.convert(Image.FORMAT_RGBA8)
	var size := image.get_size()
	var bg := _background(image)
	var diff := PackedFloat32Array()
	diff.resize(size.x * size.y)
	for y in size.y:
		for x in size.x:
			var c := image.get_pixel(x, y)
			diff[y * size.x + x] = maxf(maxf(absf(c.r - bg.r), absf(c.g - bg.g)), absf(c.b - bg.b))
	# 1. Fondo: lo que se alcanza desde los bordes pasando por puntos parecidos al fondo.
	var outside := PackedByteArray()
	outside.resize(size.x * size.y)
	var stack: Array[Vector2i] = []
	for x in size.x:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, size.y - 1))
	for y in size.y:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(size.x - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= size.x or p.y >= size.y:
			continue
		var i := p.y * size.x + p.x
		if outside[i] == 1 or diff[i] >= BACKGROUND:
			continue
		outside[i] = 1
		stack.append(p + Vector2i.RIGHT)
		stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN)
		stack.append(p + Vector2i.UP)
	# 2. Solo el libro: la mancha más grande de lo que no es fondo (los cuadraditos sueltos se van).
	var label := PackedInt32Array()
	label.resize(size.x * size.y)
	var best := 0
	var best_count := 0
	var next := 0
	for start in size.x * size.y:
		if outside[start] == 1 or label[start] != 0:
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
				if n >= 0 and outside[n] == 0 and label[n] == 0:
					label[n] = next
					queue.append(n)
		if count > best_count:
			best_count = count
			best = next
	# 3. Recorte: el libro opaco; alrededor, el halo (lo que no es fondo pero cerca del libro) se apaga.
	var shape: PackedVector2Array = Geometry2D.offset_polygon(outline, MARGIN)[0]
	var result := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var box := Rect2i()
	var first := true
	for y in size.y:
		for x in size.x:
			var i := y * size.x + x
			var c := image.get_pixel(x, y)
			var alpha := 0.0
			if label[i] == best and Geometry2D.is_point_in_polygon(Vector2(x, y), shape):
				alpha = clampf(diff[i] / GLOW, 0.0, 1.0) if _near_outside(outside, size, x, y) else 1.0
			if alpha <= 0.02:
				continue
			# Quita el fondo que se mezcló en el halo (para que no quede un borde oscuro).
			var clean := Color(clampf((c.r - bg.r * (1.0 - alpha)) / alpha, 0.0, 1.0), clampf((c.g - bg.g * (1.0 - alpha)) / alpha, 0.0, 1.0),
				clampf((c.b - bg.b * (1.0 - alpha)) / alpha, 0.0, 1.0), alpha)
			result.set_pixel(x, y, clean)
			box = Rect2i(x, y, 1, 1) if first else box.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
			first = false
	var cut := result.get_region(box.grow(4).intersection(Rect2i(Vector2i.ZERO, size)))
	_save(cut, 256, OUT + "grimorio_arte.png")
	_save(cut, 64, OUT + "grimorio_libro.png")
	quit()


## Color del fondo: el promedio de las cuatro esquinas.
func _background(image: Image) -> Color:
	var s := image.get_size() - Vector2i.ONE
	var sum := Color(0, 0, 0, 0)
	for p in [Vector2i(4, 4), Vector2i(s.x - 4, 4), Vector2i(4, s.y - 4), Vector2i(s.x - 4, s.y - 4)]:
		sum += image.get_pixelv(p)
	return sum / 4.0


## Si el punto está a menos de 6 px del fondo (borde del libro: ahí va el halo que se apaga).
func _near_outside(outside: PackedByteArray, size: Vector2i, x: int, y: int) -> bool:
	for dy in range(-6, 7, 3):
		for dx in range(-6, 7, 3):
			var px := clampi(x + dx, 0, size.x - 1)
			var py := clampi(y + dy, 0, size.y - 1)
			if outside[py * size.x + px] == 1:
				return true
	return false


func _save(image: Image, height: int, path: String) -> void:
	var copy := image.duplicate() as Image
	var width := int(round(copy.get_width() * float(height) / copy.get_height()))
	copy.resize(width, height, Image.INTERPOLATE_LANCZOS)
	copy.save_png(ProjectSettings.globalize_path(path))
	print("%s (%dx%d)" % [path, width, height])
