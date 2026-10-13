class_name SaveIndicator
extends Label
## Indicador de guardado en el HUD (esquina inferior derecha): «✔ Partida guardada» o «✘ Error al
## guardar» un momento después de cada guardado (manual o automático). No dice nada de la nube:
## solo muestra lo que el juego puede verificar (que el archivo se escribió en este equipo).

const GREEN := Color("5dff9a")
const MAG := Color("ff3ea5")
const SHOW_SECONDS := 1.6

var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -260
	offset_top = -44
	offset_right = -18
	offset_bottom = -16
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	add_theme_constant_override("outline_size", 6)
	modulate.a = 0.0
	var saves := get_node("/root/SaveManager")
	saves.saved.connect(func(_slot: int) -> void: show_state(true))
	saves.save_failed.connect(func(_slot: int, _reason: String) -> void: show_state(false))


func show_state(ok: bool) -> void:
	text = "✔ Partida guardada" if ok else "✘ Error al guardar"
	add_theme_color_override("font_color", GREEN if ok else MAG)
	if _tween:
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(SHOW_SECONDS if ok else SHOW_SECONDS * 2.0)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)
