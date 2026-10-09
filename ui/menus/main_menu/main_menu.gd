extends Control
## Menú principal: punto de entrada del juego.

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.0.0")

	# En web no se puede cerrar la aplicación y en iOS no está permitido.
	quit_button.visible = not (OS.has_feature("web") or OS.has_feature("ios"))

	# Foco inicial para poder navegar con teclado o mando (no se usa en pantallas táctiles).
	if not DisplayServer.is_touchscreen_available():
		play_button.grab_focus()


func _on_play_pressed() -> void:
	# Partida nueva: Kai empieza como un alumno común, sin habilidades.
	# (Cuando exista el guardado, aquí se ofrecerá continuar la partida.)
	GameState.reset()
	DigitalVision.reset()
	SceneManager.change_scene(SceneManager.FIRST_ROOM)


func _on_settings_pressed() -> void:
	SceneManager.change_scene(SceneManager.SETTINGS)


func _on_quit_pressed() -> void:
	SceneManager.quit_game()
