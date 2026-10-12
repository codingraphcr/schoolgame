extends SceneTree
## Recorta los sprites del jefe «Contraseña débil» de la hoja de Ariel
## (docs/arte/referencias/jefe_contrasena_sprites.webp, fondo verde liso) y arma sus animaciones.
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_jefe_contrasena.gd
##
## Para cada animación: toma la franja de su fila, la divide en cuadros (cerca de los cortes parejos,
## en la columna con menos dibujo, porque estelas y sombras se tocan), saca el verde y el borde
## verdoso, y ubica cada cuadro con las patas en el mismo punto (la mediana de las columnas de la
## mitad de abajo: así una estela hacia un lado no lo corre). Mismo tamaño de píxel que Kai: se
## muestran a mitad de escala en el mundo.
##
## Salida (assets/art/characters/jefe_contrasena/):
##   jefe_<animacion>.png → tira horizontal de cuadros (caminar y embestir, también _izq)
##   jefe.json            → por animación: archivo, tamaño de cuadro, pies, cuadros, fps y bucle

const SHEET := "res://docs/arte/referencias/jefe_contrasena_sprites.webp"
const OUT := "res://assets/art/characters/jefe_contrasena/"
const BACKGROUND := Color("598e5f")
const TOLERANCE := 0.16
const WORLD_SCALE := 0.5
## Margen alrededor del dibujo en cada cuadro.
const MARGIN := 4

## Animaciones: franja de la hoja (x desde, x hasta, y desde, y hasta), cuadros, fps y bucle.
## En la hoja, caminar y embestir miran a la derecha; el resto, de frente.
const ANIMATIONS := {
	"quieto": { "band": [10, 776, 40, 276], "frames": 4, "fps": 6.0, "loop": true },
	"caminar": { "band": [806, 1536, 40, 276], "frames": 4, "fps": 7.0, "loop": true },
	"preparar": { "band": [18, 704, 357, 510], "frames": 4, "fps": 8.0, "loop": false },
	# body: solo el cuerpo (columnas alrededor de las patas): las estelas se meten en el cuadro vecino;
	# el juego dibuja las suyas.
	"embestir": { "band": [732, 1523, 357, 510], "frames": 4, "fps": 14.0, "loop": true, "body": [-74, 84] },
	"agachado": { "band": [25, 778, 586, 742], "frames": 4, "fps": 6.0, "loop": true },
	"dano": { "band": [826, 1511, 586, 742], "frames": 4, "fps": 16.0, "loop": false },
	"muerte": { "band": [14, 903, 813, 988], "frames": 6, "fps": 6.0, "loop": false },
	"alerta": { "band": [933, 1520, 813, 988], "frames": 3, "fps": 8.0, "loop": false },
}

## Animaciones que en la hoja miran a la derecha: también se genera su versión hacia la izquierda
## (<animación>_izq).
const SIDE_ANIMATIONS: Array[String] = ["caminar", "embestir"]

var _sheet: Image


func _initialize() -> void:
	_sheet = Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	if _sheet == null:
		push_error("No se encontró la hoja: " + SHEET)
		quit(1)
		return
	_sheet.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var info := {}
	for anim_name: String in ANIMATIONS:
		var anim: Dictionary = ANIMATIONS[anim_name]
		var frames := _cut_frames(anim.band, anim.frames, anim.get("body", []))
		_save_strip(anim_name, frames, anim, info)
		# Las que miran a la derecha también hacia la izquierda: espejadas, pero con el texto de las
		# ventanas rosas al derecho (si no, "123456" se leería al revés).
		if anim_name in SIDE_ANIMATIONS:
			var left_frames: Array[Dictionary] = []
			for f in frames:
				var image := (f.image as Image).duplicate() as Image
				image.flip_x()
				_unflip_windows(image)
				left_frames.append({ "image": image, "anchor": image.get_width() - 1 - int(f.anchor) })
			_save_strip(anim_name + "_izq", left_frames, anim, info)
	var json := FileAccess.open(OUT + "jefe.json", FileAccess.WRITE)
	json.store_string(JSON.stringify({ "scale": WORLD_SCALE, "animations": info }, "\t"))
	json.close()
	quit()


## Una tira con los cuadros, todos del mismo tamaño y con los pies en el mismo punto.
func _save_strip(anim_name: String, frames: Array[Dictionary], anim: Dictionary, info: Dictionary) -> void:
	var left := 0
	var right := 0
	var up := 0
	for f in frames:
		left = maxi(left, f.anchor)
		right = maxi(right, f.image.get_width() - f.anchor)
		up = maxi(up, f.image.get_height())
	var width := left + right + MARGIN * 2
	var height := up + MARGIN * 2
	var strip := Image.create_empty(width * frames.size(), height, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		var image: Image = frames[i].image
		var at := Vector2i(i * width + MARGIN + left - frames[i].anchor, height - MARGIN - image.get_height())
		strip.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)
	var file_name := "jefe_%s.png" % anim_name
	strip.save_png(OUT + file_name)
	info[anim_name] = {
		"file": file_name, "frame_size": [width, height], "feet": [MARGIN + left, height - MARGIN],
		"frames": frames.size(), "fps": anim.fps, "loop": anim.loop,
	}
	print("%s: %d cuadro(s) de %d×%d" % [file_name, frames.size(), width, height])


## En una imagen espejada, vuelve a dar vuelta el contenido de cada ventana rosa (relleno rosa
## grande): la ventana queda en su lugar espejado pero su texto se lee al derecho.
func _unflip_windows(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# Las letras oscuras parten el rosa en pedazos: se engrosa la mancha rosa para que cada ventana
	# quede de una sola pieza.
	var pink := PackedByteArray()
	pink.resize(w * h)
	for y in h:
		for x in w:
			if _is_window_pink(img.get_pixel(x, y)):
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						var px := x + dx
						var py := y + dy
						if px >= 0 and py >= 0 and px < w and py < h:
							pink[py * w + px] = 1
	var seen := PackedByteArray()
	seen.resize(w * h)
	for y in h:
		for x in w:
			if seen[y * w + x] or not pink[y * w + x]:
				continue
			# Componente rosa conectada: su recuadro es la ventana.
			var box := Rect2i(x, y, 1, 1)
			var count := 0
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * w + x] = 1
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				count += 1
				box = box.expand(p)
				for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					var q := p + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or seen[q.y * w + q.x]:
						continue
					if pink[q.y * w + q.x]:
						seen[q.y * w + q.x] = 1
						stack.append(q)
			box.size += Vector2i.ONE
			if count < 120 or box.size.x < 18 or box.size.y < 10:
				continue
			box = box.grow(-2).intersection(Rect2i(0, 0, w, h))
			var region := img.get_region(box)
			region.flip_x()
			img.blit_rect(region, Rect2i(Vector2i.ZERO, box.size), box.position)


func _is_window_pink(c: Color) -> bool:
	return c.a > 0.0 and c.r > 0.75 and c.b > 0.6 and c.g < 0.55


## Divide la franja en count cuadros y devuelve [{ image, anchor }] (anchor: columna de las patas).
## body: [desde, hasta] respecto de las patas; se borra lo de afuera (estelas de los vecinos).
func _cut_frames(band: Array, count: int, body: Array) -> Array[Dictionary]:
	var x0: int = band[0]
	var x1: int = band[1]
	var y0: int = band[2]
	var y1: int = band[3]
	var occupancy := PackedInt32Array()
	occupancy.resize(x1 - x0)
	for x in range(x0, x1):
		var n := 0
		for y in range(y0, y1):
			if not _is_background(_sheet.get_pixel(x, y)):
				n += 1
		occupancy[x - x0] = n
	# Cortes: cerca del corte parejo, en la columna con menos dibujo.
	var cuts: Array[int] = [x0]
	var step := float(x1 - x0) / count
	for i in range(1, count):
		var guess := int(x0 + step * i)
		var best := guess
		for x in range(guess - 24, guess + 25):
			if x > x0 and x < x1 and occupancy[x - x0] < occupancy[best - x0]:
				best = x
		cuts.append(best)
	cuts.append(x1)
	var frames: Array[Dictionary] = []
	for i in count:
		var region := _sheet.get_region(Rect2i(cuts[i], y0, cuts[i + 1] - cuts[i], y1 - y0))
		_remove_background(region)
		if not body.is_empty():
			var feet := _feet_column(region)
			for y in region.get_height():
				for x in region.get_width():
					if x < feet + int(body[0]) or x > feet + int(body[1]):
						region.set_pixel(x, y, Color(0, 0, 0, 0))
		var box := region.get_used_rect()
		var image := region.get_region(box)
		frames.append({ "image": image, "anchor": _feet_column(image) })
	return frames


## Verde del fondo, o un píxel verdoso del borde (el jefe no tiene verde).
func _is_background(c: Color) -> bool:
	if Vector3(c.r - BACKGROUND.r, c.g - BACKGROUND.g, c.b - BACKGROUND.b).length() < TOLERANCE:
		return true
	return c.g > maxf(c.r, c.b) + 0.04


func _remove_background(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if _is_background(img.get_pixel(x, y)):
				img.set_pixel(x, y, Color(0, 0, 0, 0))


## Columna de las patas: la mediana de las columnas con dibujo en la mitad de abajo.
func _feet_column(img: Image) -> int:
	var xs: Array[int] = []
	for y in range(img.get_height() / 2, img.get_height()):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				xs.append(x)
	if xs.is_empty():
		return img.get_width() / 2
	xs.sort()
	return xs[xs.size() / 2]
