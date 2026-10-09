extends Control
## Pantalla de opciones, con el estilo lila del menú principal: volumen (general, música, efectos),
## pantalla completa, reducción de efectos glitch, velocidad del texto y controles configurables.
## Cada cambio se aplica y se guarda al momento (GameSettings). El Grimorio se abre con G en el juego.


@onready var back_button: Button = %BackButton
@onready var _options: Control = %Options
@onready var _controls: Control = %Controls
@onready var _master_row: SettingRow = %MasterRow
@onready var _music_row: SettingRow = %MusicRow
@onready var _sfx_row: SettingRow = %SfxRow
@onready var _fullscreen_row: SettingRow = %FullscreenRow
@onready var _glitch_row: SettingRow = %GlitchRow
@onready var _text_speed_row: SettingRow = %TextSpeedRow
@onready var _controls_row: SettingRow = %ControlsRow
@onready var _key_rows: VBoxContainer = %KeyRows
@onready var _hint: Label = %Hint
@onready var _reset_controls_button: Button = %ResetControlsButton
@onready var _controls_back_button: Button = %ControlsBackButton

## Fila de tecla que espera la tecla nueva (o null).
var _waiting_row: SettingRow


func _ready() -> void:
	GameSettings.ensure_loaded()
	_master_row.value = GameSettings.master_volume
	_music_row.value = GameSettings.music_volume
	_sfx_row.value = GameSettings.sfx_volume
	_fullscreen_row.value = GameSettings.fullscreen
	_glitch_row.value = GameSettings.reduce_glitch
	_text_speed_row.choices = GameSettings.TEXT_SPEED_NAMES
	_text_speed_row.value = GameSettings.text_speed
	# En la web el navegador decide la pantalla completa.
	_fullscreen_row.visible = not OS.has_feature("web")

	_master_row.value_changed.connect(_on_volume_changed.bind(&"master"))
	_music_row.value_changed.connect(_on_volume_changed.bind(&"music"))
	_sfx_row.value_changed.connect(_on_volume_changed.bind(&"sfx"))
	_fullscreen_row.value_changed.connect(_on_fullscreen_changed)
	_glitch_row.value_changed.connect(_on_glitch_changed)
	_text_speed_row.value_changed.connect(_on_text_speed_changed)
	_controls_row.pressed.connect(_show_controls.bind(true))
	back_button.pressed.connect(_go_back)
	_reset_controls_button.pressed.connect(_on_reset_controls)
	_controls_back_button.pressed.connect(_show_controls.bind(false))
	_build_key_rows()

	if not DisplayServer.is_touchscreen_available():
		_master_row.grab_focus()


func _input(event: InputEvent) -> void:
	# Esperando la tecla nueva para una acción: la próxima tecla que se presione es la elegida.
	if _waiting_row == null or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	var row := _waiting_row
	_waiting_row = null
	if event.keycode != KEY_ESCAPE:
		GameSettings.remap(row.get_meta(&"action"), event)
		GameSettings.save()
	_refresh_key_rows()
	_hint.text = "Elige una acción y presiona la tecla nueva. Esc cancela."
	row.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Esc (ui_cancel) cierra los controles o regresa al menú.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _controls.visible:
			_show_controls(false)
		else:
			_go_back()


func _on_volume_changed(volume: float, bus: StringName) -> void:
	match bus:
		&"master":
			GameSettings.master_volume = volume
		&"music":
			GameSettings.music_volume = volume
		&"sfx":
			GameSettings.sfx_volume = volume
	GameSettings.apply_audio()
	GameSettings.save()


func _on_fullscreen_changed(on: bool) -> void:
	GameSettings.fullscreen = on
	GameSettings.apply_display()
	GameSettings.save()


func _on_glitch_changed(on: bool) -> void:
	GameSettings.reduce_glitch = on
	GameSettings.save()


func _on_text_speed_changed(index: int) -> void:
	GameSettings.text_speed = index
	GameSettings.save()


# --- Controles ---

func _build_key_rows() -> void:
	var font: Font = _controls_row.get_theme_font(&"font")
	for entry in GameSettings.REMAPPABLE:
		var row := SettingRow.new()
		row.kind = SettingRow.Kind.KEY
		row.text = String(entry[1]).to_upper()
		row.custom_minimum_size = Vector2(0, 36)
		row.add_theme_font_override(&"font", font)
		row.add_theme_font_size_override(&"font_size", 16)
		row.set_meta(&"action", entry[0])
		row.pressed.connect(_wait_for_key.bind(row))
		_key_rows.add_child(row)
	_refresh_key_rows()


func _refresh_key_rows() -> void:
	for row: SettingRow in _key_rows.get_children():
		row.value = GameSettings.key_name(row.get_meta(&"action"))


func _wait_for_key(row: SettingRow) -> void:
	_waiting_row = row
	row.value = "PRESIONA UNA TECLA..."
	_hint.text = "Presiona la tecla nueva para «%s». Esc cancela." % row.text.capitalize()


func _on_reset_controls() -> void:
	GameSettings.reset_controls()
	GameSettings.save()
	_refresh_key_rows()


func _show_controls(show: bool) -> void:
	_waiting_row = null
	_controls.visible = show
	_options.visible = not show
	if show:
		_refresh_key_rows()
	if DisplayServer.is_touchscreen_available():
		return
	if show:
		(_key_rows.get_child(0) as Control).grab_focus()
	else:
		_controls_row.grab_focus()


func _go_back() -> void:
	SceneManager.change_scene(SceneManager.MAIN_MENU)
