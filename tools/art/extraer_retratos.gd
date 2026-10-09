extends SceneTree
## Recorta los retratos para los diálogos (estilo Hades) de la hoja de diálogos de Ariel.
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_retratos.gd
##
## Los retratos grandes quedan con fondo transparente: se borra el fondo liso desde los bordes de
## arriba y de los costados (abajo no, porque ahí la ropa toca el borde) y después el halo oscuro
## que queda alrededor. Las expresiones se recortan tal cual, con su fondo.

const SHEET := "res://docs/arte/referencias/dialogos_hoja_concepto.webp"
const KAI := "res://assets/art/characters/kai/retratos/"
const PROFESOR := "res://assets/art/characters/profesor/retratos/"

## Retratos grandes (fondo transparente): salida → zona dentro del marco.
const CUTOUTS := {
	KAI + "kai_retrato.png": Rect2i(6, 48, 348, 438),
	PROFESOR + "profesor_retrato.png": Rect2i(850, 48, 344, 440),
}
## Diferencia de color máxima con el fondo para borrarlo, y la más floja para el halo.
const TOLERANCE := 0.075
const HALO_TOLERANCE := 0.16
const HALO_PASSES := 2

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
		_cut_out(sheet.get_region(CUTOUTS[out])).save_png(out)
		print(out.get_file())
	for dir: String in EXPRESSIONS:
		var prefix := "kai_" if dir == KAI else "profesor_"
		for expression: String in EXPRESSIONS[dir]:
			var out := dir + prefix + expression + ".png"
			sheet.get_region(Rect2i(EXPRESSIONS[dir][expression], EXPRESSION_SIZE[dir])).save_png(out)
			print(out.get_file())
	quit()


func _cut_out(image: Image) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var background := image.get_pixel(2, 2)
	var done := PackedByteArray()
	done.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
	for y in int(h * 0.75):
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or done[p.y * w + p.x]:
			continue
		if _distance(image.get_pixelv(p), background) > TOLERANCE:
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
				if color.a == 0.0 or _distance(color, background) > HALO_TOLERANCE:
					continue
				if image.get_pixel(x + 1, y).a == 0.0 or image.get_pixel(x - 1, y).a == 0.0 \
						or image.get_pixel(x, y + 1).a == 0.0 or image.get_pixel(x, y - 1).a == 0.0:
					halo.append(Vector2i(x, y))
		for p in halo:
			image.set_pixelv(p, Color(0, 0, 0, 0))
	return image


func _distance(a: Color, b: Color) -> float:
	return (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0
