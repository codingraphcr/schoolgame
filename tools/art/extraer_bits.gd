extends SceneTree
## Recorta el símbolo de los BITS de la hoja de Ariel (con su fondo oscuro) para el Grimorio.
## Las monedas del juego y el ícono del HUD se dibujan por código (BitCoin.draw_coin).
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_bits.gd

const SHEET := "res://docs/arte/referencias/bits_concepto.webp"
const OUT := "res://assets/art/items/bits/bits_arte.png"
## "Diseño del símbolo": la moneda grande con su brillo.
const RECT := Rect2i(50, 196, 280, 268)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	sheet.convert(Image.FORMAT_RGBA8)
	sheet.get_region(RECT).save_png(OUT)
	print(OUT.get_file(), " ", RECT.size)
	quit()
