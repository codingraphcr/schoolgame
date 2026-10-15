extends SceneTree
## Pose del ataque hacia arriba de Kai: la misma del ataque hacia abajo (pogo_clavar, de la hoja de Ariel
## "Animación de pogo": Kai de siempre, con las dos manos en el mango), pero sin la hoja que baja. La
## Nullblade la dibuja el juego saliendo de sus manos hacia arriba (PlayerCombat._spawn_up_slash, UP_GRIP).
## Ejecutar (después de extraer_personajes_concepto.gd):
##   godot --headless --path . --script res://tools/art/generar_kai_corte_arriba.gd

const DIR := "res://assets/art/characters/kai/hd/"
const SOURCE := "kai_hd_pogo_pogo_clavar.png"
const OUT := "kai_hd_arriba_arriba_cortar.png"
## La hoja de la espada en pogo_clavar (cuadro 96×176, los pies en 48,119): de la guarda para abajo. Las
## manos y el mango quedan; las piernas (a la izquierda) también.
const BLADE := [
	Vector2(42, 104), Vector2(46, 100), Vector2(56, 98), Vector2(60, 100), Vector2(68, 110), Vector2(68, 160),
	Vector2(36, 160), Vector2(36, 112), Vector2(40, 108),
]


func _initialize() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(DIR + SOURCE))
	image.convert(Image.FORMAT_RGBA8)
	var blade := PackedVector2Array(BLADE)
	for y in image.get_height():
		for x in image.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), blade):
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	image.save_png(ProjectSettings.globalize_path(DIR + OUT))
	var json := FileAccess.open(ProjectSettings.globalize_path(DIR + "kai_hd_arriba.json"), FileAccess.WRITE)
	json.store_string(JSON.stringify({ "scale": 0.5, "animations": { "arriba_cortar": {
		"file": OUT, "frame_size": [image.get_width(), image.get_height()], "feet": [48, 119],
		"frames": 1, "fps": 1.0, "loop": false } } }, "\t"))
	json.close()
	print("%s: la pose del pogo sin la hoja" % OUT)
	quit()
