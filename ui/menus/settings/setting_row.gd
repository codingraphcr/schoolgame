@tool
class_name SettingRow
extends MainMenuOption
## Fila de la pantalla de opciones: el nombre a la izquierda y el valor a la derecha.
## Con el foco, ◀ / ▶ (o A / D, o el mando) cambian el valor; Enter o clic también lo cambian
## (en los deslizadores, el clic en la mitad izquierda baja y en la derecha sube).
## Tipos: ACTION (solo se presiona), SLIDER (0 a 1 en pasos), TOGGLE (SÍ / NO),
## CHOICE (una de varias opciones) y KEY (muestra una tecla; la pantalla la cambia al presionar).

signal value_changed(value: Variant)

enum Kind { ACTION, SLIDER, TOGGLE, CHOICE, KEY }

@export var kind := Kind.ACTION:
	set(new_kind):
		kind = new_kind
		queue_redraw()
@export var step := 0.1
@export var choices: PackedStringArray = []

## Valor actual: float (SLIDER), bool (TOGGLE), int (CHOICE) o String (KEY: nombre de la tecla).
var value: Variant = 0.0:
	set(new_value):
		value = new_value
		queue_redraw()

const VALUE_WIDTH := 220.0
const SEGMENTS := 10
const ARROW := 6.0


func _ready() -> void:
	super()
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	pressed.connect(_on_pressed)


func _gui_input(event: InputEvent) -> void:
	if kind in [Kind.ACTION, Kind.KEY]:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_change(-1)
		accept_event()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_change(1)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and kind == Kind.SLIDER:
		var left_half: bool = event.position.x < size.x - VALUE_WIDTH * 0.5 - TEXT_MARGIN
		_change(-1 if left_half else 1)
		accept_event()


func _on_pressed() -> void:
	match kind:
		Kind.TOGGLE, Kind.CHOICE:
			_change(1)


## Sube (+1) o baja (-1) el valor y avisa.
func _change(direction: int) -> void:
	match kind:
		Kind.SLIDER:
			value = snappedf(clampf(float(value) + step * direction, 0.0, 1.0), 0.01)
		Kind.TOGGLE:
			value = not bool(value)
		Kind.CHOICE:
			if choices.is_empty():
				return
			value = posmod(int(value) + direction, choices.size())
		_:
			return
	Sfx.play(&"ui_move", 1.0 + 0.1 * float(direction))
	value_changed.emit(value)


func _draw() -> void:
	super()
	if kind == Kind.ACTION:
		return
	var color := TEXT_SELECTED if is_selected() else TEXT
	var right := size.x - TEXT_MARGIN
	var middle := size.y * 0.5
	match kind:
		Kind.SLIDER:
			_draw_slider(Rect2(right - VALUE_WIDTH, middle - 6.0, VALUE_WIDTH - 72.0, 12.0), color)
			_draw_text_right("%d%%" % roundi(float(value) * 100.0), right, color)
		Kind.TOGGLE:
			_draw_choice("SÍ" if bool(value) else "NO", right, color)
		Kind.CHOICE:
			_draw_choice(choices[int(value)] if int(value) < choices.size() else "", right, color)
		Kind.KEY:
			_draw_text_right(String(value), right, color)


## Barra de segmentos (como pixeles) llena hasta el valor.
func _draw_slider(rect: Rect2, color: Color) -> void:
	var gap := 3.0
	var width := (rect.size.x - gap * (SEGMENTS - 1)) / SEGMENTS
	var filled := roundi(float(value) * SEGMENTS)
	for i in SEGMENTS:
		var segment := Rect2(rect.position.x + i * (width + gap), rect.position.y, width, rect.size.y)
		if i < filled:
			draw_rect(segment, FRAME_BORDER if is_selected() else Color(FRAME_BORDER, 0.75))
		else:
			draw_rect(segment, Color(color, 0.25), false, 1.0)


## Valor entre dos flechas: ◀ VALOR ▶ (las flechas solo se ven con el foco).
func _draw_choice(text: String, right: float, color: Color) -> void:
	var width := _text_width(text)
	var arrow_right := right - ARROW
	var text_right := arrow_right - ARROW - 10.0
	_draw_text_right(text, text_right, color)
	if is_selected():
		var middle := size.y * 0.5
		var left_tip := text_right - width - 10.0 - ARROW * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(left_tip, middle), Vector2(left_tip + ARROW, middle - ARROW), Vector2(left_tip + ARROW, middle + ARROW)]), FRAME_BORDER)
		draw_colored_polygon(PackedVector2Array([Vector2(right, middle), Vector2(arrow_right, middle - ARROW), Vector2(arrow_right, middle + ARROW)]), FRAME_BORDER)


func _draw_text_right(text: String, right: float, color: Color) -> void:
	var font := get_theme_font(&"font")
	var font_size := get_theme_font_size(&"font_size")
	var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(right - _text_width(text), baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _text_width(text: String) -> float:
	return get_theme_font(&"font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size(&"font_size")).x
