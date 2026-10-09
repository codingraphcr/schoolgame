@tool
class_name EnergyBar
extends Control
## Marco de integridad del HUD (concepto de Ariel): un corchete a la izquierda con marcas, un rombo
## abajo y las barritas de energía debajo de los cristales de vida. Hay una barrita por cada celda
## de energía (GameState.max_energy_cells: empiezan 2 y suben con la historia). La energía se
## gastará en habilidades futuras; por ahora está llena (CombatHUD.set_energy la actualiza).

const LINE := Color(0.62, 0.5, 1.0, 0.85)
const LINE_DIM := Color(0.62, 0.5, 1.0, 0.35)
const BAR_BACK := Color(0.08, 0.05, 0.18, 0.85)
const BAR_FILL := Color("8f6bff")
const BAR_SHINE := Color("efe8ff")
const DIAMOND_FILL := Color("130d26")
const PULSE := Color("b48cff")

## Primera barrita: posición y tamaño; las demás van a la derecha.
const CELL := Rect2(30, 62, 40, 8)
const CELL_GAP := 6.0

## Cantidad de barritas.
@export_range(1, 8) var cells := 2:
	set(value):
		cells = maxi(value, 1)
		queue_redraw()
## Brillo del pulso al recuperar energía (0 = nada). Lo anima pulse().
var pulse_amount := 0.0:
	set(value):
		pulse_amount = value
		queue_redraw()

## Energía actual, en barritas (puede ser fraccionaria: 1.5 = una llena y media).
@export var energy := 2.0:
	set(value):
		energy = clampf(value, 0.0, cells)
		queue_redraw()


func _draw() -> void:
	# Corchete: línea de arriba, línea vertical con marcas y rombo abajo.
	draw_line(Vector2(6, 2), Vector2(42, 2), LINE, 2.0)
	draw_line(Vector2(6, 2), Vector2(6, 56), LINE, 2.0)
	for y in range(12, 52, 8):
		draw_line(Vector2(10, y), Vector2(13, y), LINE_DIM, 1.0)
	_draw_diamond(Vector2(14, CELL.get_center().y), 8.0)
	draw_line(Vector2(6, 56), Vector2(6, CELL.get_center().y - 9.0), LINE_DIM, 1.0)
	for i in cells:
		var cell := Rect2(CELL.position + Vector2(i * (CELL.size.x + CELL_GAP), 0), CELL.size)
		if pulse_amount > 0.0:
			draw_rect(cell.grow(4), Color(PULSE, 0.35 * pulse_amount))
		draw_rect(cell.grow(2), BAR_BACK)
		draw_rect(cell.grow(2), LINE_DIM, false, 1.0)
		var fill_ratio := clampf(energy - i, 0.0, 1.0)
		if fill_ratio > 0.0:
			var fill := Rect2(cell.position, Vector2(cell.size.x * fill_ratio, cell.size.y))
			draw_rect(fill, BAR_FILL.lerp(BAR_SHINE, 0.5 * pulse_amount))
			draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2)), Color(BAR_SHINE, 0.8))


func _draw_diamond(center: Vector2, radius: float) -> void:
	var outer := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
	draw_colored_polygon(outer, LINE)
	var inner := radius - 2.5
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -inner), center + Vector2(inner, 0), center + Vector2(0, inner), center + Vector2(-inner, 0)]), DIAMOND_FILL)
	var core := radius * 0.35
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -core), center + Vector2(core, 0), center + Vector2(0, core), center + Vector2(-core, 0)]), BAR_SHINE)


## Pulso violeta breve al recuperar energía (al acertar un golpe).
func pulse() -> void:
	pulse_amount = 1.0
	create_tween().tween_property(self, "pulse_amount", 0.0, 0.25).set_ease(Tween.EASE_OUT)
