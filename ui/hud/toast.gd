class_name Toast
extends Label
## Mensaje breve en la parte inferior de la pantalla. Cualquier sistema puede mostrar uno sin
## conocer el HUD: get_tree().call_group(&"toast", &"show_message", "texto")

const DEFAULT_COLOR := Color("3ef2ff")

var _time_left := 0.0


func _ready() -> void:
	add_to_group(&"toast")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var settings := LabelSettings.new()
	settings.font_size = 20
	settings.font_color = DEFAULT_COLOR
	settings.outline_size = 8
	settings.outline_color = Color(0.02, 0.03, 0.08)
	label_settings = settings
	modulate.a = 0.0


func show_message(message: String, seconds := 3.0, color := DEFAULT_COLOR) -> void:
	text = message
	label_settings.font_color = color
	_time_left = seconds


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	modulate.a = clampf(_time_left, 0.0, 1.0)
