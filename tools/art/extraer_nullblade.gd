extends SceneTree
## Saca la Nullblade de las hojas de Ariel:
##   nullblade_arte.png   → el arte grande de "¡Nullblade obtenida!" (con su fondo oscuro), para la
##                          tarjeta de equipamiento y el Grimorio.
##   nullblade_espada.png → la espada sola (vista frontal, sin fondo) para la animación en el juego.
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_nullblade.gd

const OUT := "res://assets/art/items/nullblade/"
const CARD_SHEET := "res://docs/arte/referencias/nullblade_obtenida_concepto.webp"
const CARD_RECT := Rect2i(520, 160, 620, 280)
const SWORD_SHEET := "res://docs/arte/referencias/nullblade_concepto.webp"
## Vista frontal: el pomo arriba y la punta abajo.
const SWORD_RECT := Rect2i(40, 196, 60, 264)
## Alto de la espada en el juego (píxeles del dibujo, se muestra a escala 0,5 como Kai).
const SWORD_HEIGHT := 96
const BACKGROUND := Color("000511")
const TOLERANCE := 0.07
const OUTLINE := Color("0a0d1c")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var card := Image.load_from_file(ProjectSettings.globalize_path(CARD_SHEET))
	card.convert(Image.FORMAT_RGBA8)
	card.get_region(CARD_RECT).save_png(OUT + "nullblade_arte.png")
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SWORD_SHEET))
	sheet.convert(Image.FORMAT_RGBA8)
	var sword := sheet.get_region(SWORD_RECT)
	_remove_background(sword)
	sword = sword.get_region(sword.get_used_rect())
	var width := roundi(sword.get_width() * float(SWORD_HEIGHT) / sword.get_height())
	sword.resize(width, SWORD_HEIGHT, Image.INTERPOLATE_LANCZOS)
	for y in sword.get_height():
		for x in sword.get_width():
			var c := sword.get_pixel(x, y)
			sword.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0) if c.a >= 0.5 else Color(0, 0, 0, 0))
	var padded := Image.create_empty(sword.get_width() + 2, sword.get_height() + 2, false, Image.FORMAT_RGBA8)
	padded.blit_rect(sword, Rect2i(Vector2i.ZERO, sword.get_size()), Vector2i.ONE)
	_outline(padded)
	padded.save_png(OUT + "nullblade_espada.png")
	print("nullblade_arte.png ", CARD_RECT.size, " · nullblade_espada.png ", padded.get_size())
	quit()


## Borra el fondo (y el resplandor violeta oscuro) conectado con los bordes.
func _remove_background(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append_array([Vector2i(x, 0), Vector2i(x, h - 1)])
	for y in h:
		stack.append_array([Vector2i(0, y), Vector2i(w - 1, y)])
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen[p.y * w + p.x]:
			continue
		seen[p.y * w + p.x] = 1
		var c := img.get_pixelv(p)
		var near := Vector3(c.r - BACKGROUND.r, c.g - BACKGROUND.g, c.b - BACKGROUND.b).length() <= TOLERANCE
		var glow := c.v < 0.42 and c.b - maxf(c.r, c.g) > 0.12
		if not near and not glow:
			continue
		img.set_pixelv(p, Color(0, 0, 0, 0))
		stack.append_array([p + Vector2i.RIGHT, p + Vector2i.LEFT, p + Vector2i.DOWN, p + Vector2i.UP])


func _outline(img: Image) -> void:
	var source := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if source.get_pixel(x, y).a > 0.0:
				continue
			for n in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				var q: Vector2i = Vector2i(x, y) + n
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and source.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break
