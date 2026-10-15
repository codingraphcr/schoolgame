class_name ObjectiveDisplay
extends VBoxContainer
## OBJETIVO de la misión activa (arriba a la derecha, bajo el indicador de la Visión Digital): un panel
## oscuro con borde cian, un rombo que late y el nombre de la misión, para que no pase desapercibido
## entre el resto de la pantalla. Al cambiar el objetivo entra deslizándose, dice «NUEVO OBJETIVO» unos
## segundos y destella. Se oculta si no hay misión activa.

const CYAN := Color("3ef2ff")
const GOLD := Color("ffd166")
const PANEL := Color(0.03, 0.05, 0.12, 0.82)
const PAD := Vector2(14, 8)
## Segundos que se muestra «NUEVO OBJETIVO» después de un cambio.
const NEW_TIME := 3.0

var _title: Label
var _text: Label
var _flash := 0.0
var _new_left := 0.0
var _slide := 0.0
var _clock := 0.0
var _quest_title := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 2)
	_title = _make_label(13, GOLD)
	_text = _make_label(18, Color(0.95, 0.97, 1.0))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var game_state := get_node("/root/GameState")
	game_state.quest_started.connect(_on_quest_changed)
	game_state.quest_step_changed.connect(_on_quest_changed)
	game_state.quest_completed.connect(_on_quest_changed)
	_refresh(false)


func _process(delta: float) -> void:
	_clock += delta
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		_text.modulate = Color.WHITE.lerp(Color(CYAN, 1.0), _flash)
	if _new_left > 0.0:
		_new_left = maxf(_new_left - delta, 0.0)
		if _new_left == 0.0:
			_update_title()
	if _slide > 0.0:
		_slide = maxf(_slide - delta * 3.0, 0.0)
	# Entra deslizándose desde la derecha (solo el dibujo: no cambia el diseño del HUD).
	var offset_x := 60.0 * _slide * _slide
	_title.position.x = offset_x
	_text.position.x = offset_x
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var font := _text.get_theme_font("font")
	var width := 0.0
	for label: Label in [_title, _text]:
		var size_px := label.get_theme_font_size("font_size")
		width = maxf(width, font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x)
	width = minf(width, size.x)
	var content_h := _text.position.y + _text.size.y
	var slide_x := 60.0 * _slide * _slide
	var rect := Rect2(size.x - width - PAD.x + slide_x, -PAD.y, width + PAD.x * 2.0, content_h + PAD.y * 2.0)
	# Brillo detrás al cambiar.
	if _flash > 0.0:
		draw_rect(rect.grow(6.0 * _flash), Color(CYAN, 0.25 * _flash))
	draw_rect(rect, PANEL)
	var pulse := 0.55 + 0.45 * sin(_clock * 3.0)
	var accent := GOLD if _new_left > 0.0 else CYAN
	draw_rect(rect, Color(accent, 0.35 + 0.35 * pulse * (1.0 if _new_left > 0.0 else 0.4)), false, 1.0)
	# Barra de color a la izquierda y esquinas marcadas.
	draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), accent)
	var corner := 8.0
	for c: Vector2 in [rect.position + Vector2(rect.size.x, 0), rect.end]:
		var dir_y := 1.0 if c.y == rect.position.y else -1.0
		draw_line(c, c + Vector2(-corner, 0), accent, 2.0)
		draw_line(c, c + Vector2(0, corner * dir_y), accent, 2.0)
	# Rombo que late, a la izquierda del título.
	var title_w := font.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _title.get_theme_font_size("font_size")).x
	var center := Vector2(size.x - title_w - 12.0 + slide_x, _title.position.y + _title.size.y / 2.0)
	var r := 4.0 + pulse * 1.5
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)]), accent)


func _on_quest_changed(_quest_id: StringName) -> void:
	_refresh(true)


func _refresh(flash: bool) -> void:
	var game_state := get_node("/root/GameState")
	var objective: String = game_state.get_objective_text()
	visible = not objective.is_empty()
	_text.text = objective
	var quest := QuestDB.get_quest(game_state.active_quest)
	_quest_title = quest.title.to_upper() if quest and not quest.title.is_empty() else ""
	if flash and visible:
		_flash = 1.0
		_new_left = NEW_TIME
		_slide = 1.0
	_update_title()


func _update_title() -> void:
	if _new_left > 0.0:
		_title.text = "NUEVO OBJETIVO"
		_title.add_theme_color_override("font_color", GOLD)
	else:
		_title.text = "OBJETIVO" + (" · " + _quest_title if not _quest_title.is_empty() else "")
		_title.add_theme_color_override("font_color", Color(CYAN, 0.95))


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
