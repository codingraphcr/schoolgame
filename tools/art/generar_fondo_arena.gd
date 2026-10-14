extends SceneTree
## Pasa a pixel art el fondo de la arena de Glitch y Chip (Cámara de convergencia, dibujo de Ariel:
## docs/arte/referencias/camara_convergencia_fondo.webp) con la estética del juego: lo reduce a la
## resolución de la arena (640 px de ancho: un píxel del dibujo = un píxel del mundo, como los tiles) y
## lo deja con una paleta limitada (PALETTE_SIZE colores, como el jefe de la contraseña y Kai).
## Salida: assets/art/backgrounds/camara_convergencia.png (la dibuja ConvergenceChamber).
## Ejecutar: godot --headless --path . --script res://tools/art/generar_fondo_arena.gd

const SOURCE := "res://docs/arte/referencias/camara_convergencia_fondo.webp"
const OUT := "res://assets/art/backgrounds/camara_convergencia.png"
const WIDTH := 640
const PALETTE_SIZE := 48
const ITERATIONS := 10
## Las plataformas dibujadas se borran (en píxeles del dibujo original): en la arena se usan las del
## juego, a alturas que Kai alcanza sin doble salto (en el dibujo quedaban muy altas). Cada una se tapa
## con lo que tiene justo debajo (from "below") o justo arriba ("above": la del centro, dentro del anillo).
const ERASE := [
	{ "rect": Rect2i(168, 562, 312, 58), "from": "below" },
	{ "rect": Rect2i(1155, 560, 317, 60), "from": "below" },
	{ "rect": Rect2i(670, 435, 298, 43), "from": "above" },
]


func _initialize() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if image == null:
		push_error("No se encontró el fondo: " + SOURCE)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	for erase: Dictionary in ERASE:
		_erase(image, erase.rect, erase.from == "below")
	var height := roundi(image.get_height() * float(WIDTH) / image.get_width())
	image.resize(WIDTH, height, Image.INTERPOLATE_LANCZOS)
	var palette := _palette(image)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			var p: Color = palette[_nearest(palette, c)]
			image.set_pixel(x, y, Color(p.r, p.g, p.b, 1.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	image.save_png(OUT)
	print("Fondo de la arena: %dx%d, %d colores → %s" % [image.get_width(), image.get_height(), palette.size(), OUT])
	quit()


## Tapa la plataforma dibujada en rect con lo que tiene justo debajo (o justo arriba).
func _erase(image: Image, rect: Rect2i, from_below: bool) -> void:
	var source := Rect2i(rect.position.x, rect.end.y if from_below else rect.position.y - rect.size.y, rect.size.x, rect.size.y)
	var patch := image.get_region(source)
	image.blit_rect(patch, Rect2i(Vector2i.ZERO, patch.get_size()), rect.position)


## Paleta con k-medias sobre una muestra de los píxeles (los colores que más se usan, sin perder los
## neones: se empieza con colores repartidos por toda la imagen).
func _palette(image: Image) -> Array[Color]:
	var samples: Array[Color] = []
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			samples.append(image.get_pixel(x, y))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var centers: Array[Color] = []
	for k in PALETTE_SIZE:
		centers.append(samples[rng.randi_range(0, samples.size() - 1)])
	for iteration in ITERATIONS:
		var sums: Array[Vector3] = []
		var counts: Array[int] = []
		sums.resize(PALETTE_SIZE)
		counts.resize(PALETTE_SIZE)
		for k in PALETTE_SIZE:
			sums[k] = Vector3.ZERO
			counts[k] = 0
		for c in samples:
			var k := _nearest(centers, c)
			sums[k] += Vector3(c.r, c.g, c.b)
			counts[k] += 1
		for k in PALETTE_SIZE:
			if counts[k] > 0:
				var m := sums[k] / counts[k]
				centers[k] = Color(m.x, m.y, m.z)
			else:
				centers[k] = samples[rng.randi_range(0, samples.size() - 1)]
	return centers


func _nearest(palette: Array[Color], c: Color) -> int:
	var best := 0
	var best_d := INF
	for k in palette.size():
		var p := palette[k]
		var d := (p.r - c.r) * (p.r - c.r) * 0.3 + (p.g - c.g) * (p.g - c.g) * 0.59 + (p.b - c.b) * (p.b - c.b) * 0.11
		if d < best_d:
			best_d = d
			best = k
	return best
