extends Control
## Pantalla de configuración (provisional). Las opciones se agregarán en etapas futuras.

@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_go_back)
	if not DisplayServer.is_touchscreen_available():
		back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Esc (ui_cancel) también regresa al menú.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()


func _go_back() -> void:
	SceneManager.change_scene(SceneManager.MAIN_MENU)
