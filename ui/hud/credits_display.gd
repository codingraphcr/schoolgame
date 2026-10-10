class_name CreditsDisplay
extends HBoxContainer
## BITS del jugador en el HUD (debajo de los cristales): la moneda girando, la cantidad
## ("1,250") y la palabra BITS. Al ganar o perder BITS muestra brevemente la diferencia (+18 / −5).
## Por dentro son los créditos de GameState (GameState.credits / add_credits).

const GAIN_COLOR := Color(0.8, 0.7, 1.0)
const LOSS_COLOR := Color(1.0, 0.45, 0.5)
const LABEL_COLOR := Color(0.72, 0.64, 0.95)

var _amount: Label
var _delta: Label
var _delta_tween: Tween
var _icon: Control
var _time := 0.0
var _flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 6)

	_icon = Control.new()
	_icon.custom_minimum_size = Vector2(22, 26)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.draw.connect(func() -> void:
		BitCoin.draw_coin(_icon, _icon.size / 2.0, 8.0, cos(_time * 1.6), false, 0.5 + _flash))
	add_child(_icon)

	_amount = _make_label(Color(0.95, 0.97, 1.0), 20)
	var word := _make_label(LABEL_COLOR, 14)
	word.text = "BITS"
	_delta = _make_label(GAIN_COLOR, 18)
	_delta.modulate.a = 0.0

	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.credits_changed.connect(_on_credits_changed)
		_amount.text = format_bits(game_state.credits)


## 1250 → "1,250"
static func format_bits(amount: int) -> String:
	var digits := str(absi(amount))
	var result := ""
	while digits.length() > 3:
		result = "," + digits.right(3) + result
		digits = digits.left(digits.length() - 3)
	return ("-" if amount < 0 else "") + digits + result


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 3.0, 0.0)
	_icon.queue_redraw()


func _make_label(color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_vertical = Control.SIZE_SHRINK_END if font_size < 18 else Control.SIZE_FILL
	add_child(label)
	return label


func _on_credits_changed(credits: int, delta: int) -> void:
	_amount.text = format_bits(credits)
	if delta == 0:
		return
	if delta > 0:
		_flash = 1.0
	_delta.text = ("+%d" if delta > 0 else "−%d") % absi(delta)
	_delta.add_theme_color_override("font_color", GAIN_COLOR if delta > 0 else LOSS_COLOR)
	if _delta_tween:
		_delta_tween.kill()
	_delta.modulate.a = 1.0
	_delta_tween = create_tween()
	_delta_tween.tween_interval(0.8)
	_delta_tween.tween_property(_delta, "modulate:a", 0.0, 0.6)
