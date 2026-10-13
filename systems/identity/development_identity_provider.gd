class_name DevelopmentIdentityProvider
extends IdentityProvider
## Identidad de desarrollo: para jugar y probar desde Godot sin Steam. Es un código local al azar
## ("dev_" + 16 hexadecimales) guardado en este dispositivo; el prefijo hace imposible confundirlo
## con un Steam ID (que es solo un número). No sirve para ningún servicio en línea.

const PREFIX := "dev_"
const DEFAULT_FILE := "user://identidad_desarrollo.cfg"

## Archivo donde queda el código (las pruebas usan otro).
var file_path := DEFAULT_FILE

var _id := ""


func _init(path := DEFAULT_FILE) -> void:
	file_path = path


func kind() -> String:
	return "dev"


func start() -> bool:
	var config := ConfigFile.new()
	if config.load(file_path) == OK:
		_id = String(config.get_value("identidad", "id", ""))
	if not is_valid_id(_id):
		_id = PREFIX + Crypto.new().generate_random_bytes(8).hex_encode()
		config.set_value("identidad", "id", _id)
		config.save(file_path)
	return true


func identity_id() -> String:
	return _id


func display_name() -> String:
	return "Desarrollo (sin Steam)"


## Un id de desarrollo válido: "dev_" y 16 hexadecimales en minúscula.
static func is_valid_id(value: String) -> bool:
	if not value.begins_with(PREFIX) or value.length() != PREFIX.length() + 16:
		return false
	for character in value.substr(PREFIX.length()):
		if not "0123456789abcdef".contains(character):
			return false
	return true
