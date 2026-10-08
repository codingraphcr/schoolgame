class_name CreditsDisplay
extends HBoxContainer
## Créditos del jugador en el HUD (debajo de las máscaras). Al ganar o perder créditos
## muestra brevemente la diferencia (+100 / −50).

const ICON_COLOR := Color(0.98, 0.8, 0.3)
const GAIN_COLOR := Color(0.55, 0.95, 0.6)
const LOSS_COLOR := Color(1.0, 0.45, 0.5)

var _amount: Label
var _delta: Label
var _delta_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)

	var icon := Control.new()
	icon.custom_minimum_size = Vector2(16, 26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void:
		var c := icon.size / 2.0
		icon.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(6, 0), c + Vector2(0, 7), c + Vector2(-6, 0)]), ICON_COLOR))
	add_child(icon)

	_amount = _make_label(Color(0.95, 0.97, 1.0))
	_delta = _make_label(GAIN_COLOR)
	_delta.modulate.a = 0.0

	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.credits_changed.connect(_on_credits_changed)
		_amount.text = str(game_state.credits)


func _make_label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _on_credits_changed(credits: int, delta: int) -> void:
	_amount.text = str(credits)
	if delta == 0:
		return
	_delta.text = ("+%d" if delta > 0 else "−%d") % absi(delta)
	_delta.add_theme_color_override("font_color", GAIN_COLOR if delta > 0 else LOSS_COLOR)
	if _delta_tween:
		_delta_tween.kill()
	_delta.modulate.a = 1.0
	_delta_tween = create_tween()
	_delta_tween.tween_interval(0.8)
	_delta_tween.tween_property(_delta, "modulate:a", 0.0, 0.6)
