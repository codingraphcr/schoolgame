extends SceneTree
## Genera el sprite PROVISIONAL del profesor (sin nombre todavía), según la guía de arte de Ariel
## (docentes: camisa, cordón con credencial y una taza). Ariel lo reemplazará por su versión.
## Ejecutar: godot --headless --path . --script res://tools/art/generar_npcs.gd
## Salida: assets/art/characters/profesor/profesor_idle.png y profesor_talk.png (2 cuadros de 28×50).

const OUT := "res://assets/art/characters/profesor/"
const W := 28
const H := 50

const O := Color("0a0d1c")
const SKIN := Color("f0c39a")
const SKIN_D := Color("c98d6b")
const HAIR := Color("8b98b8")
const HAIR_D := Color("5a6788")
const SHIRT := Color("a8c4e0")
const SHIRT_D := Color("7f9cc0")
const PANTS := Color("2c3555")
const PANTS_D := Color("1b2647")
const SHOE := Color("16161f")
const LANYARD := Color("1fa5c4")
const CARD := Color("e9dfc6")
const MUG := Color("a8384a")
const GLASSES := Color("2a2233")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save_strip("profesor_idle.png", [{ "bob": 0 }, { "bob": 1 }])
	_save_strip("profesor_talk.png", [{ "arm": "up" }, { "arm": "open", "bob": 1 }])
	print("Profesor generado en ", OUT)
	quit()


func _save_strip(file: String, poses: Array) -> void:
	var sheet := PixelPainter.new(W * poses.size(), H)
	for i in poses.size():
		var frame := PixelPainter.new(W, H)
		_paint(frame, poses[i])
		frame.outline(O)
		sheet.paste(frame, i * W, 0)
	sheet.save(OUT + file)


func _paint(p: PixelPainter, pose: Dictionary) -> void:
	var bob: int = pose.get("bob", 0)
	var arm: String = pose.get("arm", "mug")
	# Piernas y zapatos (no se mueven con la respiración).
	p.rect(10, 32, 8, 14, PANTS)
	p.rect(14, 37, 1, 9, PANTS_D)
	p.rect(16, 32, 2, 14, PANTS_D)
	p.rect(9, 46, 5, 3, SHOE)
	p.rect(15, 46, 5, 3, SHOE)
	# Torso: camisa con sombra a la derecha.
	var y := bob
	p.rect(8, 18 + y, 12, 15 - y, SHIRT)
	p.rect(17, 18 + y, 3, 15 - y, SHIRT_D)
	# Cordón con credencial.
	p.line(11, 18 + y, 14, 24 + y, LANYARD)
	p.line(17, 18 + y, 14, 24 + y, LANYARD)
	p.rect(12, 24 + y, 5, 4, CARD)
	p.px(13, 25 + y, LANYARD)
	# Brazo izquierdo (lado del espectador): siempre abajo salvo al gesticular abierto.
	if arm == "open":
		p.rect(4, 19 + y, 4, 3, SHIRT)
		p.rect(2, 18 + y, 3, 3, SKIN)
	else:
		p.rect(5, 19 + y, 3, 12, SHIRT)
		p.rect(5, 31 + y, 3, 2, SKIN)
	# Brazo derecho: con la taza, o levantado al explicar.
	if arm == "up":
		p.rect(20, 14 + y, 3, 7, SHIRT_D)
		p.rect(20, 11 + y, 3, 3, SKIN)
	else:
		p.rect(20, 19 + y, 3, 11, SHIRT_D)
		p.rect(20, 30 + y, 3, 2, SKIN)
		if arm == "mug":
			p.rect(21, 29 + y, 4, 5, MUG)
			p.px(25, 30 + y, MUG)
			p.px(25, 32 + y, MUG)
			p.rect(22, 29 + y, 2, 1, CARD)
	# Cuello y cabeza.
	p.rect(12, 16 + y, 4, 2, SKIN_D)
	p.rect(9, 5 + y, 10, 11, SKIN)
	p.rect(17, 6 + y, 2, 10, SKIN_D)
	# Pelo canoso, con entradas.
	p.rect(9, 3 + y, 10, 3, HAIR)
	p.rect(9, 6 + y, 2, 4, HAIR)
	p.rect(17, 6 + y, 2, 3, HAIR_D)
	p.rect(12, 3 + y, 4, 1, SKIN)
	# Lentes y bigote.
	p.rect(10, 9 + y, 4, 3, GLASSES)
	p.rect(15, 9 + y, 3, 3, GLASSES)
	p.px(11, 10 + y, CARD)
	p.px(16, 10 + y, CARD)
	p.px(14, 9 + y, GLASSES)
	p.rect(11, 13 + y, 6, 1, HAIR)
