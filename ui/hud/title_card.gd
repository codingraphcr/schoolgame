class_name TitleCard
extends Control
## Título grande en el centro de la pantalla (p. ej. "EL DESPERTAR" al terminar el prólogo).
## Aparece solo cuando se completa una misión con completion_title, o con show_title().

const CYAN := Color("3ef2ff")

@export var fade_time := 0.8
@export var hold_time := 2.5

var _title: Label
var _subtitle: Label
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_subtitle = _make_label(box, 18, Color(CYAN, 0.9))
	_title = _make_label(box, 56, Color(0.95, 0.98, 1.0))
	get_node("/root/GameState").quest_completed.connect(_on_quest_completed)


func is_showing() -> bool:
	return visible


func show_title(title: String, subtitle := "") -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = not subtitle.is_empty()
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_time)
	_tween.tween_interval(hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(func() -> void: visible = false)


func _on_quest_completed(quest_id: StringName) -> void:
	var quest := QuestDB.get_quest(quest_id)
	if quest and not quest.completion_title.is_empty():
		show_title(quest.completion_title, quest.completion_subtitle)


func _make_label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
