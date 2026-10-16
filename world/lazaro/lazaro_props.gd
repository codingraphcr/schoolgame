@tool
extends Node2D
## Arte provisional de la Estación Lázaro (instalación DIGITAL de protección y recuperación de sistemas, Capítulo 3),
## dibujado por código hasta que Ariel lo dibuje: tecnología antigua y avanzada, superficies blancas con detalles
## azules, cámaras de mantenimiento, circuitos que brillan y una sensación de abandono (luces apagadas, polvo de datos).
## Recuerda al cuarto viejo de la Nullblade sin ser el mismo lugar. Con la alarma (ALARM_FLAG), todo se tiñe de rojo.
## Variantes: vestibulo, superior, inferior, nucleo, escape (cambia la distribución de los detalles).

const ALARM_FLAG := &"lazaro_alarma"
const POWER_FLAG := &"lazaro_energia_restablecida"
const WALL := Color("e4eaf2")
const PANEL := Color("ccd6e4")
const LINE := Color("aab8cc")
const BLUE := Color("3a7adf")
const CYAN := Color("3ef2ff")
const RED := Color("ff4a5a")
const DARK := Color("0a1220")

@export var width := 960.0
@export var floor_y := 304.0
@export_enum("vestibulo", "superior", "inferior", "nucleo", "escape", "exterior") var variant := "vestibulo"
## Cámaras de mantenimiento (x).
@export var chambers: PackedFloat32Array = []
## Huecos del piso (x desde, x hasta): se ve el vacío de datos (el piso de colisión también tiene el hueco).
@export var gaps: PackedVector2Array = []

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _flag(flag: StringName) -> bool:
	return not Engine.is_editor_hint() and has_node("/root/GameState") and get_node("/root/GameState").has_flag(flag)


func _paint(c: VectorCanvas, t: float) -> void:
	var f := floor_y
	var alarm := _flag(ALARM_FLAG)
	var powered := _flag(POWER_FLAG) or variant == "exterior"
	var accent := RED if alarm else BLUE
	var glow := RED if alarm else CYAN
	if variant == "exterior":
		c.gradient_rect(Rect2(0, 0, width, f), Color("0a1a2a"), Color("05101a"))
		# El muro exterior de la estación a la derecha y el bosque a la izquierda.
		c.draw_rect(Rect2(width * 0.55, 30, width * 0.45, f - 30), WALL.darkened(0.25))
		var x := width * 0.55 + 20.0
		while x < width:
			c.draw_line(Vector2(x, 40), Vector2(x, f), LINE.darkened(0.3), 1.0)
			x += 60.0
		c.draw_line(Vector2(width * 0.55, 120), Vector2(width, 120), accent, 2.0)
		for k in 6:
			var tx := 40.0 + k * width * 0.08
			c.draw_line(Vector2(tx, f), Vector2(tx + 8, f - 160), Color("3a6a8a"), 3.0)
			c.draw_circle(Vector2(tx + 8, f - 166), 4.0, Color(CYAN, 0.6))
	else:
		c.draw_rect(Rect2(0, 0, width, f), WALL.darkened(0.08 if powered else 0.35))
		# Paneles y juntas.
		var x := 0.0
		while x < width:
			c.draw_rect(Rect2(x + 4, 24, 88, f - 60), PANEL.darkened(0.0 if powered else 0.3))
			c.draw_line(Vector2(x, 0), Vector2(x, f), LINE, 1.0)
			x += 96.0
		c.draw_rect(Rect2(0, 0, width, 20), WALL.darkened(0.3))
		c.draw_rect(Rect2(0, f - 36, width, 36), WALL.darkened(0.2))
		# Una línea de circuito azul que recorre la pared (con pulsos si hay energía).
		c.draw_line(Vector2(0, 60), Vector2(width, 60), Color(accent, 0.9 if powered else 0.35), 2.0)
		c.draw_line(Vector2(0, f - 44), Vector2(width, f - 44), Color(accent, 0.7 if powered else 0.25), 2.0)
		if powered:
			for k in 4:
				var px := fmod(t * 120.0 + k * width / 4.0, width)
				c.draw_circle(Vector2(px, 60), 3.0, glow)
		# Cámaras de mantenimiento: cápsulas con vidrio (vacías, empañadas).
		for cx in chambers:
			var capsule := Rect2(cx - 26, f - 140, 52, 104)
			c.draw_rect(capsule, Color("f4f8fc"))
			c.draw_rect(capsule, accent, false, 2.0)
			c.draw_rect(Rect2(capsule.position + Vector2(8, 10), Vector2(36, 70)), Color(DARK, 0.85))
			c.draw_rect(Rect2(capsule.position + Vector2(10, 12), Vector2(10, 66)), Color(1, 1, 1, 0.08))
			c.draw_circle(capsule.position + Vector2(26, 92), 4.0, Color(glow, 0.8 if powered else 0.2))
		# Polvo de datos (abandono).
		for k in 12:
			var dx := fmod(k * 83.0 + t * 6.0, width)
			var dy := 30.0 + fmod(k * 47.0 + t * 4.0, f - 60.0)
			c.draw_rect(Rect2(dx, dy, 2, 2), Color(1, 1, 1, 0.12))
	# Piso blanco con una franja.
	c.draw_rect(Rect2(0, f, width, 60), Color("c4cedc"))
	c.draw_line(Vector2(0, f + 2), Vector2(width, f + 2), accent, 2.0)
	for gap in gaps:
		c.gradient_rect(Rect2(gap.x, f, gap.y - gap.x, 60), Color("0a1220"), Color("02060c"))
		c.draw_line(Vector2(gap.x, f), Vector2(gap.x, f + 60), glow, 2.0)
		c.draw_line(Vector2(gap.y, f), Vector2(gap.y, f + 60), glow, 2.0)
		for k in 5:
			var bx := gap.x + fmod(k * 61.0 + t * 20.0, gap.y - gap.x)
			c.draw_rect(Rect2(bx, f + 10 + k * 9, 2, 2), Color(glow, 0.5))
	if alarm and fmod(t, 1.0) < 0.5:
		c.draw_rect(Rect2(0, 0, width, f + 60), Color(RED, 0.08))
	if variant == "vestibulo" or variant == "escape":
		c.crisp_text(Vector2(0, 46), "ESTACIÓN LÁZARO · PROTECCIÓN Y RECUPERACIÓN DE SISTEMAS", 9, Color("1a2a4a"), HORIZONTAL_ALIGNMENT_CENTER, width)
