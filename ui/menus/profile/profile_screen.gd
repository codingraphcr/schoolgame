class_name ProfileScreen
extends Control
## «Mi perfil»: el nombre del jugador (Steam, o «Desarrollo (sin Steam)»), tiempo total de juego, la
## partida actual (año, capítulo, nivel, lugar), Ecos, habilidades, % de historia y % educativo,
## estadísticas educativas, logros y último guardado. Datos de ProfileStats; nada privado de la
## cuenta. Esc o «Volver» cierra; emite closed.

signal closed

const CYAN := Color("3ef2ff")
const GREEN := Color("5dff9a")
const TEXT := Color("d8e4ff")
const DIM := Color("8a96b8")
const PANEL := Color("070b18")

var stats := {}


static func open(parent: Node) -> ProfileScreen:
	var screen := ProfileScreen.new()
	screen.name = "Perfil"
	parent.add_child(screen)
	return screen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stats = ProfileStats.compute(get_node("/root/SaveManager"))
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	closed.emit()
	queue_free()


## Las filas «Dato: valor» que muestra la pantalla (también para las pruebas).
func rows() -> Array[Array]:
	var meta: Dictionary = stats["meta"]
	var result: Array[Array] = [["Tiempo total de juego", SlotSelect.format_time(int(stats["tiempo_total"])) + "  (%d %s)" % [stats["partidas"], "partida" if stats["partidas"] == 1 else "partidas"]]]
	if int(stats["ranura"]) == 0:
		result.append(["Partida actual", "Todavía no hay partidas guardadas"])
		return result
	result.append(["Partida actual", "Ranura %d · %s" % [stats["ranura"], SlotSelect._chapter_text(meta)]])
	result.append(["Lugar", String(meta.get("lugar", "")) if not String(meta.get("lugar", "")).is_empty() else "—"])
	result.append(["Ecos", "%d" % stats["ecos"]])
	var skills: PackedStringArray = stats["habilidades"]
	result.append(["Habilidades", ", ".join(skills) if not skills.is_empty() else "Ninguna todavía"])
	result.append(["Historia completada", "%d %%" % int(meta.get("historia", 0))])
	result.append(["Contenido educativo", "%d %%" % int(meta.get("educativo", 0))])
	result.append(["Estadísticas educativas", "%d comandos aprendidos · %d terminales resueltas · %d desafíos" % [stats["comandos"], stats["terminales"], stats["desafios"]]])
	var achievements: PackedStringArray = stats["logros"]
	result.append(["Logros", ", ".join(achievements) if not achievements.is_empty() else "Aún no hay logros (llegarán con Steam)"])
	result.append(["Último guardado", SlotSelect.format_date(int(stats["ultimo_guardado"]))])
	return result


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.04, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PANEL, 0.96)
	style.set_border_width_all(2)
	style.border_color = CYAN
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	_label(column, "MI PERFIL", CYAN, 26)
	_label(column, String(get_node("/root/IdentityManager").display_name), GREEN, 20)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for row in rows():
		var key := _label(grid, row[0], DIM, 16)
		key.autowrap_mode = TextServer.AUTOWRAP_OFF
		var value := _label(grid, row[1], TEXT, 16)
		value.custom_minimum_size = Vector2(470, 0)
	var back := Button.new()
	back.text = "◀ Volver (Esc)"
	back.custom_minimum_size = Vector2(200, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	column.add_child(back)
	if not DisplayServer.is_touchscreen_available():
		back.grab_focus.call_deferred()


func _label(parent: Control, text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label
