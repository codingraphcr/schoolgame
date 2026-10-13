extends SceneTree
## Recorta los sprites del jefe «Contraseña débil» de la hoja de Ariel
## (docs/arte/referencias/jefe_contrasena_sprites.webp, fondo verde liso) y arma sus animaciones.
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_jefe_contrasena.gd
##
## Para cada animación: toma la franja de su fila, la divide en cuadros (cerca de los cortes parejos,
## en la columna con menos dibujo, porque estelas y sombras se tocan), saca el verde y el borde
## verdoso, iguala la escala de las filas y quieta el cuerpo (ver _normalize), y ubica cada cuadro con
## los pies en el mismo punto (la mediana de las columnas de la
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
## Ancho de la ventana "123456" en todas las animaciones (en píxeles de la hoja; la mayoría de las
## filas ya la tiene así).
const WINDOW_WIDTH := 50
## Cuántos píxeles tarda en desvanecerse lo que queda fuera del cuerpo (estelas de la embestida).
const BODY_FADE := 26.0
## Pixel art como Kai (ver _pixelate): tamaño del píxel, colores de la paleta y contorno.
const PIXEL_BLOCK := 1.5
const PALETTE_SIZE := 28
const OUTLINE := Color("0a0d1c")

## Animaciones: franja de la hoja (x desde, x hasta, y desde, y hasta), cuadros, fps y bucle.
## En la hoja, caminar y embestir miran a la derecha; el resto, de frente.
const ANIMATIONS := {
	"quieto": { "band": [10, 776, 40, 276], "frames": 4, "fps": 6.0, "loop": true, "steady": true },
	"caminar": { "band": [806, 1536, 40, 276], "frames": 4, "fps": 7.0, "loop": true, "steady": true },
	"preparar": { "band": [18, 704, 357, 510], "frames": 4, "fps": 8.0, "loop": false, "steady": true },
	# body: el cuerpo (columnas alrededor de las patas; adelante, a la derecha, va la ventana inclinada);
	# atrás se desvanece la estela, que se mete en el
	# cuadro vecino;
	# el juego dibuja las suyas.
	# steady "shift": todos los cuadros se corren igual; scale fija: la estela rosa engaña a la medición;
	# cuts: dónde termina cada cuadro (justo delante del jefe). Las estelas pintadas cambiaban en cada
	# cuadro y parpadeaban: destreak las borra detrás de las patas y el juego dibuja las suyas, parejas.
	"embestir": { "band": [732, 1523, 357, 510], "frames": 4, "fps": 11.0, "loop": true, "body": [-72, 130], "steady": "shift", "scale": 1.06, "fade": 16.0, "only_body": true, "destreak": 0,
		"cuts": [974, 1183, 1361] },
	"agachado": { "band": [25, 778, 586, 742], "frames": 4, "fps": 6.0, "loop": true, "steady": true },
	"dano": { "band": [826, 1511, 586, 742], "frames": 4, "fps": 16.0, "loop": false, "steady": true },
	"muerte": { "band": [14, 903, 813, 988], "frames": 6, "fps": 6.0, "loop": false, "steady": true },
	"alerta": { "band": [933, 1520, 813, 988], "frames": 3, "fps": 8.0, "loop": false, "steady": true },
}

## Animaciones que en la hoja miran a la derecha: también se genera su versión hacia la izquierda
## (<animación>_izq).
const SIDE_ANIMATIONS: Array[String] = ["caminar", "embestir"]

var _sheet: Image
var _out := OUT
## Cuántos píxeles tarda en desvanecerse lo de afuera del cuerpo en la animación actual.
var _fade := BODY_FADE
## Si en la animación actual se deja solo la figura conectada más grande (sin trazos sueltos).
var _only_body := false
## destreak: detrás de esta columna (desde los pies) se borran las estelas rosas pintadas.
var _destreak := INF
const STREAK_THICKNESS := 7
## Tamaño del píxel del dibujo (1 = como Kai; 1,5 = un poco más pixelado; 2 = el doble, más retro).
var _block: float = PIXEL_BLOCK


func _initialize() -> void:
	_sheet = Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	if _sheet == null:
		push_error("No se encontró la hoja: " + SHEET)
		quit(1)
		return
	_sheet.convert(Image.FORMAT_RGBA8)
	# Opcional: -- bloque=2 salida=res://carpeta/ (para probar otro tamaño de píxel sin pisar el juego).
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("bloque="):
			_block = float(arg.get_slice("=", 1))
		elif arg.begins_with("salida="):
			_out = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	# 1. Recorta, iguala el tamaño y quieta el cuerpo de cada animación.
	var all := {}
	var pixels: Array[Color] = []
	for anim_name: String in ANIMATIONS:
		var anim: Dictionary = ANIMATIONS[anim_name]
		_fade = float(anim.get("fade", BODY_FADE))
		_only_body = anim.get("only_body", false)
		_destreak = float(anim.get("destreak", INF))
		var frames := _normalize(_cut_frames(anim.band, anim.frames, anim.get("body", []), anim.get("cuts", [])), anim)
		# pick: solo esos cuadros (en la embestida, el más limpio; el movimiento lo da el juego).
		if anim.has("pick"):
			var picked: Array[Dictionary] = []
			for i: int in anim.pick:
				picked.append(frames[i])
			frames = picked
		all[anim_name] = frames
		# Las que miran a la derecha también hacia la izquierda: espejadas, pero con el texto de las
		# ventanas rosas al derecho (si no, "123456" se leería al revés).
		if anim_name in SIDE_ANIMATIONS:
			var left_frames: Array[Dictionary] = []
			for f in frames:
				var image := (f.image as Image).duplicate() as Image
				image.flip_x()
				_unflip_windows(image)
				left_frames.append({ "image": image, "anchor": image.get_width() - 1 - int(f.anchor) })
			all[anim_name + "_izq"] = left_frames
		for f in frames:
			_sample_pixels(f.image, pixels)
	# 2. Pixel art como Kai: una sola paleta para todas las animaciones, bordes duros y contorno.
	var palette := _palette(pixels, PALETTE_SIZE)
	var info := {}
	for anim_name: String in all:
		var frames: Array[Dictionary] = all[anim_name]
		for f in frames:
			f.image = _pixelate(f.image, palette)
			# El contorno agrega un píxel (del tamaño del bloque) a la izquierda.
			f.anchor = int(f.anchor) + roundi(_block)
		_save_strip(anim_name, frames, ANIMATIONS[anim_name.trim_suffix("_izq")], info)
	var json := FileAccess.open(_out + "jefe.json", FileAccess.WRITE)
	json.store_string(JSON.stringify({ "scale": WORLD_SCALE, "animations": info }, "\t"))
	json.close()
	quit()


## Iguala el tamaño y quieta el cuerpo. En la hoja, cada fila está dibujada a otra escala (quieto es
## un 30 % más grande que preparar), así que el jefe se agrandaba y achicaba al cambiar de animación:
## se escala cada animación para que la ventana "123456" (igual en todos los dibujos) mida
## WINDOW_WIDTH. Y como las patas no están en el mismo lugar en cada dibujo, el cuerpo saltaba de un
## cuadro al otro: con "steady" se alinea por la ventana, en el mismo punto en todas las animaciones
## (el torso queda quieto y se mueven las patas
## y las ventanas de encima). Los cuadros donde la ventana ya se deshizo (muerte) usan las patas.
func _normalize(frames: Array[Dictionary], anim: Dictionary) -> Array[Dictionary]:
	var boxes: Array[Rect2i] = []
	var widths: Array[int] = []
	for f in frames:
		var box := _window_box(f.image)
		boxes.append(box)
		widths.append(box.size.x)
	var sorted := widths.duplicate()
	sorted.sort()
	# Mediana de las ventanas enteras (en la muerte se van deshaciendo).
	var whole := sorted.filter(func(w: int) -> bool: return w >= sorted[-1] * 0.7)
	var median := maxi(whole[whole.size() / 2], 1)
	if anim.has("scale"):
		median = roundi(WINDOW_WIDTH / float(anim.scale))
	# "scale": escala fija (si la estela rosa confunde la medición de la ventana).
	var factor: float = anim.get("scale", float(WINDOW_WIDTH) / median)
	var result: Array[Dictionary] = []
	var offsets: Array[float] = []
	for i in frames.size():
		var image := (frames[i].image as Image).duplicate() as Image
		var size := Vector2i(roundi(image.get_width() * factor), roundi(image.get_height() * factor))
		image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		var anchor := roundi(int(frames[i].anchor) * factor)
		var window_x := boxes[i].get_center().x * factor
		var valid := boxes[i].size.x >= median * 0.7
		if valid:
			offsets.append(window_x - anchor)
		result.append({ "image": image, "anchor": anchor, "window_x": window_x, "valid": valid })
	if anim.has("steady") and not offsets.is_empty():
		# El torso (la ventana) queda en el mismo punto en todas las animaciones: cambiar de una a
		# otra ya no corre al jefe. Los cuadros sin ventana se corren lo mismo que los demás.
		offsets.sort()
		var offset := offsets[offsets.size() / 2]
		for f in result:
			var per_frame: bool = f.valid and anim.steady is bool
			f.anchor = roundi(f.window_x) if per_frame else roundi(f.anchor + offset)
	return result


## Recuadro de la ventana rosa más grande (la de "123456"). Sin engrosar el rosa: engrosado, las
## ventanas que están juntas se unían en una sola.
func _window_box(img: Image) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var pink := PackedByteArray()
	pink.resize(w * h)
	for y in h:
		for x in w:
			if _is_window_pink(img.get_pixel(x, y)):
				pink[y * w + x] = 1
	var seen := PackedByteArray()
	seen.resize(w * h)
	var best := Rect2i()
	var best_count := 0
	for y in h:
		for x in w:
			if seen[y * w + x] or not pink[y * w + x]:
				continue
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
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and not seen[q.y * w + q.x] and pink[q.y * w + q.x]:
						seen[q.y * w + q.x] = 1
						stack.append(q)
			if count > best_count:
				best_count = count
				best = Rect2i(box.position, box.size + Vector2i.ONE)
	return best


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
	strip.save_png(_out + file_name)
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
			# Solo ventanas: ni manchas chicas ni la estela rosa de la embestida (larga y rala).
			var fill := count / float(box.size.x * box.size.y)
			if count < 120 or box.size.x < 18 or box.size.y < 10 or box.size.x > 130 or box.size.y > 85 or fill < 0.4:
				continue
			box = box.grow(-2).intersection(Rect2i(0, 0, w, h))
			var region := img.get_region(box)
			region.flip_x()
			img.blit_rect(region, Rect2i(Vector2i.ZERO, box.size), box.position)


func _is_window_pink(c: Color) -> bool:
	return c.a > 0.0 and c.r > 0.75 and c.b > 0.6 and c.g < 0.55


## Divide la franja en count cuadros y devuelve [{ image, anchor }] (anchor: columna de las patas).
## body: [desde, hasta] respecto de las patas; se borra lo de afuera (estelas de los vecinos).
func _cut_frames(band: Array, count: int, body: Array, fixed_cuts: Array) -> Array[Dictionary]:
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
	# Cortes a mano (en la embestida la estela de cada cuadro se mete en el anterior: el corte va
	# justo delante del jefe).
	if not fixed_cuts.is_empty():
		cuts.assign([x0] + fixed_cuts + [x1])
	var frames: Array[Dictionary] = []
	for i in count:
		var region := _sheet.get_region(Rect2i(cuts[i], y0, cuts[i + 1] - cuts[i], y1 - y0))
		_remove_background(region)
		if _destreak != INF:
			_remove_streaks(region)
		if not body.is_empty():
			# Fuera del cuerpo se desvanece de a poco (las estelas no quedan cortadas en recto).
			var feet := _feet_column(region)
			var from := feet + int(body[0])
			var to := feet + int(body[1])
			for y in region.get_height():
				for x in region.get_width():
					var outside := maxf(from - x, x - to)
					if outside <= 0.0:
						continue
					var c := region.get_pixel(x, y)
					c.a *= clampf(1.0 - outside / _fade, 0.0, 1.0)
					region.set_pixel(x, y, c)
		if _only_body:
			_keep_largest(region)
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


# --- Pixel art (como Kai y los retratos) ---

## Agrega a pixels una muestra de los colores visibles de la imagen (para armar la paleta).
func _sample_pixels(img: Image, pixels: Array[Color]) -> void:
	for y in range(0, img.get_height(), 3):
		for x in range(0, img.get_width(), 3):
			var c := img.get_pixel(x, y)
			if c.a >= 0.5:
				pixels.append(c)


## Como Kai: reduce por bloques (_block) conservando las líneas oscuras, deja cada píxel opaco o
## transparente, usa la paleta común, agrega un contorno oscuro y vuelve a agrandar sin suavizar.
## Saca la fila de contorno de abajo (así las patas siguen apoyadas en el suelo).
func _pixelate(image: Image, palette: Array[Color]) -> Image:
	# Bloques enteros: reducción que conserva las líneas. Bloques de 1,5: reducción fina (Lanczos),
	# que no oscurece ni empasta el dibujo.
	var small: Image
	if is_equal_approx(_block, roundf(_block)):
		small = _downsample(image, roundi(_block))
	else:
		small = _downsample_fine(image, _block)
	var w := small.get_width()
	var h := small.get_height()
	for y in h:
		for x in w:
			var c := small.get_pixel(x, y)
			if c.a > 0.0:
				small.set_pixel(x, y, palette[_nearest_index(palette, c)])
	var padded := Image.create_empty(w + 2, h + 1, false, Image.FORMAT_RGBA8)
	padded.blit_rect(small, Rect2i(0, 0, w, h), Vector2i(1, 1))
	var shape := padded.duplicate() as Image
	for y in padded.get_height():
		for x in padded.get_width():
			if shape.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < padded.get_width() and q.y < padded.get_height() and shape.get_pixelv(q).a > 0.0:
					padded.set_pixel(x, y, OUTLINE)
					break
	padded.resize(roundi(padded.get_width() * _block), roundi(padded.get_height() * _block), Image.INTERPOLATE_NEAREST)
	return padded


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
			color = Color((color.r - 0.5) * 1.12 + 0.5, (color.g - 0.5) * 1.12 + 0.5, (color.b - 0.5) * 1.12 + 0.5)
			color.s = minf(color.s * 1.1, 1.0)
			small.set_pixel(x, y, color)
	return small


## Paleta de "count" colores que mejor representa los píxeles (k-means sobre una muestra).
func _palette(pixels: Array[Color], count: int) -> Array[Color]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sample: Array[Color] = []
	for i in range(0, pixels.size(), maxi(pixels.size() / 8000, 1)):
		sample.append(pixels[i])
	var centers: Array[Color] = []
	for i in count:
		centers.append(sample[rng.randi_range(0, sample.size() - 1)])
	for iteration in 14:
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


## Reduce dividiendo el tamaño por block con Lanczos (para bloques no enteros); alfa duro y un poco
## más de contraste y color, como _downsample.
func _downsample_fine(image: Image, block: float) -> Image:
	var small := image.duplicate() as Image
	small.resize(maxi(roundi(image.get_width() / block), 1), maxi(roundi(image.get_height() / block), 1), Image.INTERPOLATE_LANCZOS)
	for y in small.get_height():
		for x in small.get_width():
			var c := small.get_pixel(x, y)
			if c.a < 0.5:
				small.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			c = Color((c.r - 0.5) * 1.12 + 0.5, (c.g - 0.5) * 1.12 + 0.5, (c.b - 0.5) * 1.12 + 0.5)
			c.s = minf(c.s * 1.1, 1.0)
			small.set_pixel(x, y, c)
	return small


## Deja solo la figura conectada más grande (el cuerpo): la estela de la embestida son trazos sueltos.
func _keep_largest(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	var sizes: Array[int] = [0]
	for y in h:
		for x in w:
			if label[y * w + x] != 0 or img.get_pixel(x, y).a < 0.5:
				continue
			var id := sizes.size()
			var count := 0
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			label[y * w + x] = id
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				count += 1
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var q := p + Vector2i(dx, dy)
						if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or label[q.y * w + q.x] != 0:
							continue
						if img.get_pixelv(q).a >= 0.5:
							label[q.y * w + q.x] = id
							stack.append(q)
			sizes.append(count)
	var best := 0
	for i in range(1, sizes.size()):
		if best == 0 or sizes[i] > sizes[best]:
			best = i
	for y in h:
		for x in w:
			if label[y * w + x] != best:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


## Borra las estelas pintadas detrás del jefe en la embestida (el juego dibuja las suyas, parejas):
## detrás de la columna _destreak, el rosa/magenta brillante y las líneas horizontales delgadas
## (de arriba a abajo miden pocos píxeles; el cuerpo y las patas son más gruesos).
func _remove_streaks(region: Image) -> void:
	var limit := mini(_feet_column(region) + int(_destreak), region.get_width())
	for y in region.get_height():
		for x in limit:
			var c := region.get_pixel(x, y)
			if c.a > 0.0 and c.r > 0.55 and c.r > c.b * 0.8 and c.g < 0.5:
				region.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in limit:
		var y := 0
		while y < region.get_height():
			if region.get_pixel(x, y).a <= 0.0:
				y += 1
				continue
			var start := y
			while y < region.get_height() and region.get_pixel(x, y).a > 0.0:
				y += 1
			if y - start < STREAK_THICKNESS:
				for k in range(start, y):
					region.set_pixel(x, k, Color(0, 0, 0, 0))
