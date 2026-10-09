@tool
class_name EnergyBar
extends Control
## Marco de integridad del HUD (concepto de Ariel): un corchete a la izquierda con marcas, un rombo
## abajo y la barra de energía debajo de los cristales de vida. La energía se gastará en
## habilidades futuras; por ahora se muestra llena hasta que exista ese sistema
## (CombatHUD.set_energy(actual, máximo) la actualiza).

const LINE := Color(0.62, 0.5, 1.0, 0.85)
const LINE_DIM := Color(0.62, 0.5, 1.0, 0.35)
const BAR_BACK := Color(0.08, 0.05, 0.18, 0.85)
const BAR_FILL := Color("8f6bff")
const BAR_SHINE := Color("efe8ff")
const DIAMOND_FILL := Color("130d26")

## Rectángulo de la barra dentro del control.
const BAR := Rect2(30, 62, 190, 8)

## Energía de 0 a 1.
@export_range(0.0, 1.0) var ratio := 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	# Corchete: línea de arriba, línea vertical con marcas y rombo abajo.
	draw_line(Vector2(6, 2), Vector2(42, 2), LINE, 2.0)
	draw_line(Vector2(6, 2), Vector2(6, 56), LINE, 2.0)
	for y in range(12, 52, 8):
		draw_line(Vector2(10, y), Vector2(13, y), LINE_DIM, 1.0)
	_draw_diamond(Vector2(14, BAR.get_center().y), 8.0)
	draw_line(Vector2(6, 56), Vector2(6, BAR.get_center().y - 9.0), LINE_DIM, 1.0)
	# Barra de energía.
	draw_rect(BAR.grow(2), BAR_BACK)
	draw_rect(BAR.grow(2), LINE_DIM, false, 1.0)
	var fill := Rect2(BAR.position, Vector2(BAR.size.x * ratio, BAR.size.y))
	if fill.size.x > 0.0:
		draw_rect(fill, BAR_FILL)
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2)), Color(BAR_SHINE, 0.8))
	# Marcas cada cuarto.
	for i in range(1, 4):
		var x := BAR.position.x + BAR.size.x * i / 4.0
		draw_line(Vector2(x, BAR.position.y), Vector2(x, BAR.end.y), Color(DIAMOND_FILL, 0.6), 1.0)


func _draw_diamond(center: Vector2, radius: float) -> void:
	var outer := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
	draw_colored_polygon(outer, LINE)
	var inner := radius - 2.5
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -inner), center + Vector2(inner, 0), center + Vector2(0, inner), center + Vector2(-inner, 0)]), DIAMOND_FILL)
	var core := radius * 0.35
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -core), center + Vector2(core, 0), center + Vector2(0, core), center + Vector2(-core, 0)]), BAR_SHINE)
