extends VectorCanvas
## Fondo del escritorio de la computadora del profesor, visto desde dentro por el alma digital de
## Kai: fondo de pantalla, íconos y la barra de tareas
## (que es el suelo). La ventana de la cuenta y el SPAM son nodos aparte.

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const WALL_TOP := Color("0d1a3a")
const WALL_BOTTOM := Color("1b2f63")

@export var area := Rect2(0, 0, 960, 360)
@export var floor_y := 304.0
## Mensaje mientras el nivel está en construcción (vacío = ninguno).
@export var construction_note := "NIVEL EN CONSTRUCCIÓN · TAREA H4"


func _ready() -> void:
	painter = _paint
	animated = true
	super()


func _paint(c: VectorCanvas, t: float) -> void:
	c.gradient_rect(area, WALL_TOP, WALL_BOTTOM)
	# Fondo de pantalla: el escudo del colegio en grande, muy tenue.
	var logo := Vector2(area.get_center().x, 150)
	c.glow(logo, 120.0, Color(CYAN, 0.08))
	c.crisp_text(logo + Vector2(-160, -10), "COLEGIO", 28, Color(CYAN, 0.12), HORIZONTAL_ALIGNMENT_CENTER, 320)
	# Cuadrícula de píxeles de la pantalla.
	for x in range(int(area.position.x), int(area.end.x), 24):
		c.draw_line(Vector2(x, area.position.y), Vector2(x, floor_y), Color(CYAN, 0.04), 0.5)
	# Íconos del escritorio.
	var icons := ["Mis documentos", "Correo", "Navegador", "Papelera"]
	for i in icons.size():
		var pos := Vector2(40, 56 + i * 52)
		c.gradient_box(Rect2(pos, Vector2(22, 18)), 3.0, Color("3a6fc4"), Color("234a8a"), Color(CYAN, 0.6), 0.8)
		c.crisp_text(pos + Vector2(-20, 30), icons[i], 5, Color(0.9, 0.95, 1.0, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 62)
	# Barra de tareas (el suelo).
	c.draw_rect(Rect2(area.position.x, floor_y, area.size.x, area.end.y - floor_y), Color("0a1124"))
	c.draw_line(Vector2(area.position.x, floor_y), Vector2(area.end.x, floor_y), Color(CYAN, 0.9), 1.5, true)
	c.gradient_box(Rect2(8, floor_y + 6, 40, 16), 3.0, Color("2d8fd4"), Color("1b5c99"), Color(CYAN, 0.7), 0.8)
	c.crisp_text(Vector2(8, floor_y + 18), "Inicio", 5, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 40)
	c.crisp_text(Vector2(area.end.x - 60, floor_y + 18), "08:00", 6, Color(0.9, 0.95, 1.0, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 50)
	if not construction_note.is_empty():
		c.crisp_text(Vector2(area.get_center().x - 160, 250), construction_note, 7, Color(CYAN, 0.5 + 0.3 * sin(t * 3.0)), HORIZONTAL_ALIGNMENT_CENTER, 320)
