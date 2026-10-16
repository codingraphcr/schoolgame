class_name GrimorioAlert
extends CanvasLayer
## Un aviso del Grimorio arriba de la pantalla (no pausa el juego): líneas cortas en mayúsculas, con el estilo del
## Grimorio. Lo usan la advertencia de integridad de la conexión y los mensajes de la señal protectora (Capítulo 3).
## Se cierra solo. Uso: await GrimorioAlert.show_lines(nodo, ["ADVERTENCIA DE INTEGRIDAD", ...], 3.0).finished

signal finished

const BORDER := Color("b46bff")
const TEXT := Color("e6deff")
const BLUE := Color("6fd3ff")

var lines: PackedStringArray = []
var seconds := 3.0
## Color del aviso: violeta (el Grimorio) o azul (la señal protectora).
var accent := BORDER


static func show_lines(from: Node, text_lines: PackedStringArray, duration := 3.0, color := BORDER) -> GrimorioAlert:
	var alert := GrimorioAlert.new()
	alert.lines = text_lines
	alert.seconds = duration
	alert.accent = color
	from.get_tree().current_scene.add_child(alert)
	return alert


func _ready() -> void:
	layer = 60
	add_to_group(&"grimorio_alert")
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.12, 0.92)
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.custom_minimum_size = Vector2(520, 0)
	panel.position = Vector2(-260, 70)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 4)
	panel.add_child(column)
	for i in lines.size():
		var label := Label.new()
		label.text = lines[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override(&"font_size", 18 if i == 0 else 15)
		label.add_theme_color_override(&"font_color", accent if i == 0 else TEXT)
		column.add_child(label)
	panel.modulate.a = 0.0
	Sfx.play(&"popup_open")
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_interval(seconds)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		finished.emit()
		queue_free())
