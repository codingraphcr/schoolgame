extends CanvasLayer
## Gestiona los cambios entre pantallas con una transición de fundido.
## Está registrado como autoload "SceneManager" en project.godot,
## por lo que se puede usar desde cualquier script: SceneManager.change_scene(...)

const MAIN_MENU := "res://ui/menus/main_menu/main_menu.tscn"
const SETTINGS := "res://ui/menus/settings/settings_screen.tscn"
## Primera sala jugable: Zona 0, Pasillo + Laboratorio.
const FIRST_ROOM := "res://world/zones/zone0/pasillo_laboratorio.tscn"

const FADE_DURATION := 0.25
const FADE_COLOR := Color(0.039, 0.067, 0.141)

var _fade_rect: ColorRect
var _is_changing := false


func _ready() -> void:
	# Se dibuja por encima de cualquier pantalla.
	layer = 100

	_fade_rect = ColorRect.new()
	_fade_rect.color = FADE_COLOR
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)


## Cambia a la escena indicada. Ignora nuevas peticiones mientras hay una transición en curso.
func change_scene(scene_path: String) -> void:
	if _is_changing:
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneManager: no existe la escena '%s'." % scene_path)
		return

	_is_changing = true
	# Bloquea clics durante la transición para evitar dobles pulsaciones.
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	await _fade_to(1.0)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneManager: no se pudo cargar '%s' (error %d)." % [scene_path, error])
	# El cambio de escena se aplica al final del cuadro actual.
	await get_tree().process_frame
	await _fade_to(0.0)

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_changing = false


## Fundido a negro, ejecuta midpoint (p. ej. mover al jugador) y vuelve a mostrar la escena.
## Se usa para reaparecer tras un peligro o al morir, sin cambiar de escena.
func transition(midpoint: Callable) -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0)
	midpoint.call()
	await get_tree().process_frame
	await _fade_to(0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func quit_game() -> void:
	get_tree().quit()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_DURATION)
	await tween.finished
