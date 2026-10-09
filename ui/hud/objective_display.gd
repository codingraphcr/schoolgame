class_name ObjectiveDisplay
extends VBoxContainer
## OBJETIVO de la misión activa (arriba a la derecha, bajo el indicador de la Visión Digital).
## Destella al cambiar. Se oculta si no hay misión activa.

const CYAN := Color("3ef2ff")

var _title: Label
var _text: Label
var _flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_BEGIN
	_title = _make_label(13, Color(CYAN, 0.85))
	_title.text = "OBJETIVO"
	_text = _make_label(16, Color(0.93, 0.96, 1.0))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var game_state := get_node("/root/GameState")
	game_state.quest_started.connect(_on_quest_changed)
	game_state.quest_step_changed.connect(_on_quest_changed)
	game_state.quest_completed.connect(_on_quest_changed)
	_refresh(false)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		_text.modulate = Color.WHITE.lerp(Color(CYAN, 1.0), _flash)


func _on_quest_changed(_quest_id: StringName) -> void:
	_refresh(true)


func _refresh(flash: bool) -> void:
	var objective: String = get_node("/root/GameState").get_objective_text()
	visible = not objective.is_empty()
	_text.text = objective
	if flash and visible:
		_flash = 1.0


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
