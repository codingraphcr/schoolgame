class_name GameSettings
extends RefCounted
## Ajustes del jugador: volumen, pantalla completa, velocidad del texto, reducción de efectos glitch
## y teclas. Se guardan en user://ajustes.cfg y se aplican al cargarse (ensure_loaded()).
## Es una clase estática: se usa como GameSettings.text_speed_factor(), sin instancias.

## Archivo de los ajustes (las pruebas usan otro para no tocar los del jugador).
static var path := "user://ajustes.cfg"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

## Velocidades del texto de los diálogos (multiplicador; 0 = aparece entero al instante).
const TEXT_SPEED_NAMES: PackedStringArray = ["LENTA", "NORMAL", "RÁPIDA", "INSTANTÁNEA"]
const TEXT_SPEED_FACTORS: Array[float] = [0.55, 1.0, 1.7, 0.0]

## Acciones que el jugador puede cambiar de tecla, con su nombre en pantalla.
const REMAPPABLE: Array[Array] = [
	[&"move_left", "Moverse a la izquierda"],
	[&"move_right", "Moverse a la derecha"],
	[&"move_up", "Mirar arriba"],
	[&"move_down", "Mirar abajo"],
	[&"jump", "Saltar"],
	[&"attack", "Atacar"],
	[&"dash", "Dash"],
	[&"vision", "Visión Digital"],
	[&"interact", "Interactuar"],
	[&"aegis_fire", "Disparo Aegis"],
	[&"aegis_platform", "Plataforma Aegis"],
	[&"heal", "Curarse"],
	[&"ultimate", "Dominio Nulo"],
	[&"grimorio", "Abrir grimorio"],
	[&"pause", "Pausa"],
]

## Nombres en español de las teclas especiales.
const KEY_NAMES := {
	"Space": "ESPACIO", "Escape": "ESC", "Enter": "ENTER", "Shift": "SHIFT", "Ctrl": "CTRL",
	"Alt": "ALT", "Tab": "TAB", "Backspace": "BORRAR", "Left": "IZQUIERDA", "Right": "DERECHA",
	"Up": "ARRIBA", "Down": "ABAJO",
}

static var master_volume := 1.0
static var music_volume := 0.8
static var sfx_volume := 1.0
static var fullscreen := false
## Índice en TEXT_SPEED_NAMES.
static var text_speed := 1
static var reduce_glitch := false

static var _loaded := false
## Teclas originales de cada acción (para "Restablecer controles").
static var _default_keys: Dictionary[StringName, int] = {}


## Carga los ajustes guardados (una sola vez) y los aplica.
static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_register_extra_actions()
	for entry in REMAPPABLE:
		var key := _first_key(entry[0])
		if key:
			_default_keys[entry[0]] = _keycode_of(key)
	var config := ConfigFile.new()
	if config.load(path) == OK:
		master_volume = config.get_value("audio", "general", master_volume)
		music_volume = config.get_value("audio", "musica", music_volume)
		sfx_volume = config.get_value("audio", "efectos", sfx_volume)
		fullscreen = config.get_value("pantalla", "completa", fullscreen)
		reduce_glitch = config.get_value("pantalla", "reducir_glitch", reduce_glitch)
		text_speed = clampi(config.get_value("texto", "velocidad", text_speed), 0, TEXT_SPEED_NAMES.size() - 1)
		for entry in REMAPPABLE:
			var keycode: int = config.get_value("controles", String(entry[0]), 0)
			if keycode != 0:
				_set_key(entry[0], keycode)
	apply_audio()
	apply_display()


static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "general", master_volume)
	config.set_value("audio", "musica", music_volume)
	config.set_value("audio", "efectos", sfx_volume)
	config.set_value("pantalla", "completa", fullscreen)
	config.set_value("pantalla", "reducir_glitch", reduce_glitch)
	config.set_value("texto", "velocidad", text_speed)
	for entry in REMAPPABLE:
		var key := _first_key(entry[0])
		if key and _keycode_of(key) != _default_keys.get(entry[0], 0):
			config.set_value("controles", String(entry[0]), _keycode_of(key))
	config.save(path)


# --- Audio y pantalla ---

## Volumen de los buses Master, Music y SFX (los crea si no existen).
static func apply_audio() -> void:
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(_ensure_bus(MUSIC_BUS), music_volume)
	_set_bus_volume(_ensure_bus(SFX_BUS), sfx_volume)


static func apply_display() -> void:
	# En modo sin ventana (pruebas, servidor) y en la web no se cambia el modo de la ventana.
	if DisplayServer.get_name() == "headless" or OS.has_feature("web"):
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


# --- Lo que usan los demás sistemas ---

## Multiplicador de la velocidad del texto (0 = instantáneo).
static func text_speed_factor() -> float:
	ensure_loaded()
	return TEXT_SPEED_FACTORS[text_speed]


## Intensidad de los efectos glitch (temblores, parpadeos, estática): 1 normal, menos si se reducen.
static func glitch_factor() -> float:
	ensure_loaded()
	return 0.25 if reduce_glitch else 1.0


# --- Controles ---

## Nombre de la tecla de una acción (p. ej. "J"), o "—" si no tiene.
static func key_name(action: StringName) -> String:
	var key := _first_key(action)
	if key == null:
		return "—"
	var code := key.keycode
	if key.physical_keycode != 0 and DisplayServer.get_name() == "headless":
		code = key.physical_keycode
	elif key.physical_keycode != 0:
		code = DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode)
	var label := OS.get_keycode_string(code)
	return KEY_NAMES.get(label, label.to_upper())


## Cambia la tecla de una acción (reemplaza la primera tecla; los botones del mando no se tocan).
static func remap(action: StringName, event: InputEventKey) -> void:
	_set_key(action, event.physical_keycode if event.physical_keycode != 0 else event.keycode)


static func reset_controls() -> void:
	for action in _default_keys:
		_set_key(action, _default_keys[action])


static func _set_key(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	var old := _first_key(action)
	if old:
		InputMap.action_erase_event(action, old)
	var key := InputEventKey.new()
	key.physical_keycode = keycode as Key
	InputMap.action_add_event(action, key)


static func _first_key(action: StringName) -> InputEventKey:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event
	return null


static func _keycode_of(key: InputEventKey) -> int:
	return key.physical_keycode if key.physical_keycode != 0 else key.keycode


static func _ensure_bus(bus_name: StringName) -> StringName:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")
	return bus_name


static func _set_bus_volume(bus_name: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_mute(index, volume <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))


## Acciones nuevas que todavía no están en project.godot (se registran al cargar los ajustes).
## grimorio: G abre el Grimorio durante el juego.
static func _register_extra_actions() -> void:
	if not InputMap.has_action(&"grimorio"):
		InputMap.add_action(&"grimorio")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_G
		InputMap.action_add_event(&"grimorio", key)
