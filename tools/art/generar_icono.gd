extends SceneTree
## Arma el ícono del juego (el que se ve en el escritorio, la barra de tareas y la ventana) con el
## logo de Ariel (docs/arte/referencias/logo_nullveil.webp):
##   nullveil_icon.png → 256×256 (config/icon del proyecto: ícono de la ventana).
##   nullveil.ico      → 16, 24, 32, 48, 64, 128 y 256 px en un solo archivo (Windows: el .exe
##                       exportado y config/windows_native_icon).
## Fondo transparente (el negro del logo se quita). Los tamaños chicos usan un recorte más cerrado
## sobre la N, para que se lea en 16 o 32 px.
## Ejecutar: godot --headless --path . --script res://tools/art/generar_icono.gd

const SOURCE := "res://docs/arte/referencias/logo_nullveil.webp"
const OUT := "res://assets/icon/"
const SIZES: Array[int] = [16, 24, 32, 48, 64, 128, 256]
## Recorte cuadrado (en el logo de 1254 px): entero para los grandes, más cerca de la N para los chicos.
const CROP_LARGE := Rect2i(97, 97, 1060, 1060)
const CROP_SMALL := Rect2i(190, 210, 860, 860)
const SMALL_UP_TO := 48
## Desde este brillo un píxel cuenta como dibujado; el negro se queda hasta HALO_SOLID px del dibujo
## y se desvanece hasta HALO_FADE px (en el logo de 1254 px).
const DRAWN_FROM := 0.25
const HALO_SOLID := 14.0
const HALO_FADE := 46.0


func _initialize() -> void:
	var logo := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if logo == null:
		push_error("No se encontró el logo: " + SOURCE)
		quit(1)
		return
	logo.convert(Image.FORMAT_RGBA8)
	logo = _transparent(logo)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var entries: Array[PackedByteArray] = []
	for size in SIZES:
		var image := logo.get_region(CROP_SMALL if size <= SMALL_UP_TO else CROP_LARGE)
		image.resize(size, size, Image.INTERPOLATE_LANCZOS)
		# Como se hace siempre: 256 en PNG y los demás en mapa de bits (los lee todo Windows).
		entries.append(image.save_png_to_buffer() if size >= 256 else _dib(image))
		if size == 256:
			image.save_png(OUT + "nullveil_icon.png")
	_save_ico(OUT + "nullveil.ico", entries)
	print("Ícono generado en ", OUT)
	quit()


## Fondo negro → transparente (Ariel lo prefirió así) sin perder los detalles: el logo se ve igual
## que sobre negro porque cerca del dibujo el negro se queda (bordes oscuros, grietas, el anillo y el
## brillo violeta); se vuelve transparente de a poco solo lejos de lo dibujado (HALO_SOLID → HALO_FADE).
func _transparent(source: Image) -> Image:
	var image := source.duplicate() as Image
	var w := image.get_width()
	var h := image.get_height()
	# Distancia (en píxeles) de cada punto a lo dibujado: dos pasadas, como un mapa de distancias.
	var dist := PackedFloat32Array()
	dist.resize(w * h)
	for y in h:
		for x in w:
			dist[y * w + x] = 0.0 if image.get_pixel(x, y).v > DRAWN_FROM else 1e9
	var diagonal := sqrt(2.0)
	for y in h:
		for x in w:
			var i := y * w + x
			var d := dist[i]
			if x > 0:
				d = minf(d, dist[i - 1] + 1.0)
			if y > 0:
				d = minf(d, dist[i - w] + 1.0)
				if x > 0:
					d = minf(d, dist[i - w - 1] + diagonal)
				if x < w - 1:
					d = minf(d, dist[i - w + 1] + diagonal)
			dist[i] = d
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			var d := dist[i]
			if x < w - 1:
				d = minf(d, dist[i + 1] + 1.0)
			if y < h - 1:
				d = minf(d, dist[i + w] + 1.0)
				if x < w - 1:
					d = minf(d, dist[i + w + 1] + diagonal)
				if x > 0:
					d = minf(d, dist[i + w - 1] + diagonal)
			dist[i] = d
	for y in h:
		for x in w:
			var alpha := 1.0 - smoothstep(HALO_SOLID, HALO_FADE, dist[y * w + x])
			var c := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))
	return image


## Imagen de un tamaño del .ico como mapa de bits de 32 bits (BGRA, de abajo hacia arriba), con
## la máscara AND en cero (la transparencia la da el alfa).
func _dib(image: Image) -> PackedByteArray:
	var size := image.get_width()
	var mask_row := ((size + 31) / 32) * 4
	var data := PackedByteArray()
	data.resize(40)
	data.encode_u32(0, 40)  # Tamaño del encabezado.
	data.encode_s32(4, size)
	data.encode_s32(8, size * 2)  # Alto doble: color + máscara.
	data.encode_u16(12, 1)  # Planos.
	data.encode_u16(14, 32)  # Bits por píxel.
	data.encode_u32(16, 0)  # Sin compresión.
	data.encode_u32(20, size * size * 4 + mask_row * size)
	for y in range(size - 1, -1, -1):
		for x in size:
			var c := image.get_pixel(x, y)
			data.append(c.b8)
			data.append(c.g8)
			data.append(c.r8)
			data.append(c.a8)
	var mask := PackedByteArray()
	mask.resize(mask_row * size)
	data.append_array(mask)
	return data


## Un .ico con una imagen por tamaño (lo leen Windows y la exportación de Godot).
func _save_ico(path: String, pngs: Array[PackedByteArray]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_16(0)  # Reservado.
	file.store_16(1)  # Tipo: ícono.
	file.store_16(SIZES.size())
	var offset := 6 + 16 * SIZES.size()
	for i in SIZES.size():
		var size := SIZES[i]
		file.store_8(0 if size >= 256 else size)  # Ancho (0 = 256).
		file.store_8(0 if size >= 256 else size)  # Alto.
		file.store_8(0)  # Colores de paleta (ninguno).
		file.store_8(0)  # Reservado.
		file.store_16(1)  # Planos.
		file.store_16(32)  # Bits por píxel.
		file.store_32(pngs[i].size())
		file.store_32(offset)
		offset += pngs[i].size()
	for png in pngs:
		file.store_buffer(png)
	file.close()
