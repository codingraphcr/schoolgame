extends Control
## Menú principal: punto de entrada del juego.
## Fondo con el título (arte de Ariel) y las opciones al estilo de su concepto (MainMenuOption).

## Cuánto se acerca el fondo en su movimiento lento (1.0 = nada) y cuánto tarda en ir y volver.
const BACKGROUND_ZOOM := 1.035
const BACKGROUND_CYCLE := 18.0

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton
@onready var credits_back_button: Button = %CreditsBackButton
@onready var version_label: Label = %VersionLabel
@onready var _background: TextureRect = %Background
@onready var _buttons: Control = %Buttons
@onready var _credits: Control = %Credits


func _ready() -> void:
	# Ajustes guardados del jugador (volumen, pantalla, teclas).
	GameSettings.ensure_loaded()
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_show_credits.bind(true))
	credits_back_button.pressed.connect(_show_credits.bind(false))
	quit_button.pressed.connect(_on_quit_pressed)

	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.0.0")

	# En web no se puede cerrar la aplicación y en iOS no está permitido.
	quit_button.visible = not (OS.has_feature("web") or OS.has_feature("ios"))

	# Foco inicial para poder navegar con teclado o mando (no se usa en pantallas táctiles).
	if not DisplayServer.is_touchscreen_available():
		play_button.grab_focus()

	_animate_background()
	# Las opciones aparecen suavemente.
	_buttons.modulate.a = 0.0
	create_tween().tween_property(_buttons, "modulate:a", 1.0, 0.6).set_delay(0.2)


func _unhandled_input(event: InputEvent) -> void:
	if _credits.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_show_credits(false)


## El fondo se acerca y se aleja muy despacio para que la escena no se vea quieta.
func _animate_background() -> void:
	_background.pivot_offset = _background.size * 0.5
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_background, "scale", Vector2.ONE * BACKGROUND_ZOOM, BACKGROUND_CYCLE * 0.5)
	tween.tween_property(_background, "scale", Vector2.ONE, BACKGROUND_CYCLE * 0.5)


func _show_credits(show: bool) -> void:
	_credits.visible = show
	_buttons.visible = not show
	if DisplayServer.is_touchscreen_available():
		return
	if show:
		credits_back_button.grab_focus()
	else:
		credits_button.grab_focus()


func _on_play_pressed() -> void:
	# Partida nueva: Kai empieza como un alumno común, sin habilidades.
	# (Cuando exista el guardado, aquí se ofrecerá continuar la partida.)
	GameState.reset()
	DigitalVision.reset()
	GameState.start_quest(&"prologo")
	SceneManager.change_scene(SceneManager.FIRST_ROOM)


func _on_settings_pressed() -> void:
	SceneManager.change_scene(SceneManager.SETTINGS)


func _on_quit_pressed() -> void:
	SceneManager.quit_game()
