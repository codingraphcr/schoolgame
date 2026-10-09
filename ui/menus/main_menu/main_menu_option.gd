@tool
class_name MainMenuOption
extends Button
## Opción del menú principal al estilo del concepto de Ariel: texto lila con letras separadas y,
## la seleccionada, dentro de un marco lila con un rombo en cada punta.
## La selección sigue al foco (teclado o mando) y el mouse la mueve al pasar por encima.

const TEXT := Color(0.78, 0.74, 0.98)
const TEXT_SELECTED := Color(0.97, 0.95, 1.0)
const FRAME_FILL := Color(0.3, 0.2, 0.62, 0.55)
const FRAME_BORDER := Color(0.74, 0.64, 1.0)
const DIAMOND_FILL := Color(0.09, 0.06, 0.2)
## Separación de los rombos respecto del borde del botón.
const DIAMOND_INSET := 12.0
## Margen del texto a cada lado (deja lugar a los rombos).
const TEXT_MARGIN := 36.0

var _empty := StyleBoxEmpty.new()
var _frame := StyleBoxFlat.new()


func _ready() -> void:
	_frame.bg_color = FRAME_FILL
	_frame.border_color = FRAME_BORDER
	_frame.set_border_width_all(2)
	_frame.content_margin_left = TEXT_MARGIN
	_frame.content_margin_right = TEXT_MARGIN
	_empty.content_margin_left = TEXT_MARGIN
	_empty.content_margin_right = TEXT_MARGIN
	_frame.expand_margin_left = -DIAMOND_INSET
	_frame.expand_margin_right = -DIAMOND_INSET
	_frame.shadow_color = Color(0.55, 0.4, 1.0, 0.25)
	_frame.shadow_size = 10
	for state in [&"focus", &"pressed", &"disabled", &"hover_pressed"]:
		add_theme_stylebox_override(state, _empty)
	add_theme_color_override(&"font_color", TEXT)
	add_theme_color_override(&"font_focus_color", TEXT_SELECTED)
	add_theme_color_override(&"font_hover_color", TEXT_SELECTED)
	add_theme_color_override(&"font_pressed_color", TEXT_SELECTED)
	add_theme_color_override(&"font_hover_pressed_color", TEXT_SELECTED)
	focus_entered.connect(_update_selected)
	focus_exited.connect(_update_selected)
	mouse_entered.connect(_on_mouse_entered)
	visibility_changed.connect(_update_selected)
	_update_selected()


func is_selected() -> bool:
	return has_focus()


func _on_mouse_entered() -> void:
	if not disabled and focus_mode != FOCUS_NONE:
		grab_focus()


func _update_selected() -> void:
	var style: StyleBox = _frame if is_selected() else _empty
	add_theme_stylebox_override(&"normal", style)
	add_theme_stylebox_override(&"hover", style)
	queue_redraw()


func _draw() -> void:
	if not is_selected():
		return
	var middle := size.y * 0.5
	_draw_diamond(Vector2(DIAMOND_INSET, middle))
	_draw_diamond(Vector2(size.x - DIAMOND_INSET, middle))


func _draw_diamond(center: Vector2) -> void:
	draw_colored_polygon(_diamond(center, 11.0), FRAME_BORDER)
	draw_colored_polygon(_diamond(center, 8.0), DIAMOND_FILL)
	draw_colored_polygon(_diamond(center, 4.0), FRAME_BORDER)


func _diamond(center: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0),
		center + Vector2(0, radius), center + Vector2(-radius, 0)])
