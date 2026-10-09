extends SceneTree
## Recorta los retratos para los diálogos (estilo Hades) de las hojas de concepto.
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_retratos.gd
##
## Los retratos conservan su fondo; la caja de diálogo los funde con un degradado en los bordes.

## Hoja → [salida, zona] por retrato.
const PORTRAITS := {
	"res://docs/arte/referencias/kai_hoja_concepto.webp": {
		"res://assets/art/characters/kai/retratos/kai_retrato.png": Rect2i(795, 15, 266, 350),
	},
	"res://docs/arte/referencias/profesor_hoja_concepto.webp": {
		"res://assets/art/characters/profesor/retratos/profesor_retrato.png": Rect2i(0, 76, 398, 456),
		# Expresiones: primeros planos de la cara. No se usan como retrato porque cambian el encuadre;
		# sirven de referencia para dibujarlas con el mismo encuadre que profesor_retrato.png.
		"res://assets/art/characters/profesor/retratos/profesor_normal.png": Rect2i(32, 574, 214, 127),
		"res://assets/art/characters/profesor/retratos/profesor_serio.png": Rect2i(264, 574, 195, 127),
		"res://assets/art/characters/profesor/retratos/profesor_pensativo.png": Rect2i(477, 574, 193, 127),
		"res://assets/art/characters/profesor/retratos/profesor_sorprendido.png": Rect2i(688, 574, 188, 127),
		"res://assets/art/characters/profesor/retratos/profesor_sonriente.png": Rect2i(894, 574, 195, 127),
		"res://assets/art/characters/profesor/retratos/profesor_preocupado.png": Rect2i(1107, 574, 191, 127),
	},
}


func _initialize() -> void:
	for source: String in PORTRAITS:
		var sheet := Image.load_from_file(ProjectSettings.globalize_path(source))
		if sheet == null:
			push_error("No se encontró la hoja: " + source)
			continue
		sheet.convert(Image.FORMAT_RGBA8)
		for out: String in PORTRAITS[source]:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
			sheet.get_region(PORTRAITS[source][out]).save_png(out)
			print(out.get_file())
	quit()
