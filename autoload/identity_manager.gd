class_name PlayerIdentity
extends Node
## Quién está jugando (la identidad), para separar las partidas de cada persona en un mismo equipo.
## Ver docs/arquitectura/SISTEMA_USUARIOS_STEAM.md.
##
## La identidad la da un proveedor: Steam cuando esté integrado (T9, GodotSteam) o, si no hay
## Steam, la de desarrollo (DevelopmentIdentityProvider: "dev_" + código local). El id técnico
## nunca es el nombre visible, que puede cambiar.
##
## Cada identidad tiene su carpeta de partidas: user://partidas/<SteamID64> (la que sincroniza
## Steam Auto-Cloud con {64BitSteamID}) o user://partidas/dev_<código>. Ninguna identidad ve las
## partidas de otra. No se guardan contraseñas, tickets ni secretos de Steamworks.
##
## Uso: IdentityManager.display_name · IdentityManager.saves_root() · IdentityManager.is_steam()

signal identity_changed

## Carpeta de todas las partidas (las pruebas usan otra).
var base_root := "user://partidas"
var kind := ""
var identity_id := ""
var display_name := ""
## Si Steam está disponible en esta ejecución (falso hasta integrar GodotSteam en T9).
var steam_available := false

var _provider: IdentityProvider


func _ready() -> void:
	# Al correr las pruebas automáticas (--script), las partidas van a una carpeta aparte que se
	# vacía al empezar: una prueba nunca toca las partidas reales del equipo.
	if is_test_run():
		base_root = "user://pruebas_partidas"
		_remove_dir(ProjectSettings.globalize_path(base_root))
	else:
		# Los datos pasaron a una carpeta propia (%APPDATA%\Nullveil): la primera vez se copian los de
		# la carpeta vieja de Godot, antes de leer la identidad, las partidas o las opciones.
		UserDataMigration.migrate(UserDataMigration.old_dir(), OS.get_user_data_dir())
	start_default()


## Si el juego corre una prueba automática (godot --script …).
static func is_test_run() -> bool:
	return OS.get_cmdline_args().has("--script")


## Elige el proveedor: Steam si está disponible (T9); si no, la identidad de desarrollo.
func start_default() -> void:
	var file := "user://pruebas_identidad.cfg" if is_test_run() else DevelopmentIdentityProvider.DEFAULT_FILE
	use_provider(DevelopmentIdentityProvider.new(file))


## Usa ese proveedor (también para las pruebas: simular otra persona en el mismo equipo).
func use_provider(provider: IdentityProvider) -> bool:
	if provider == null or not provider.start() or not is_valid_folder(provider.identity_id()):
		push_warning("IdentityManager: el proveedor de identidad no está disponible.")
		return false
	_provider = provider
	kind = provider.kind()
	identity_id = provider.identity_id()
	display_name = provider.display_name()
	identity_changed.emit()
	return true


func is_steam() -> bool:
	return kind == "steam"


func has_identity() -> bool:
	return not identity_id.is_empty()


## Carpeta de partidas de la identidad actual ("" si no hay identidad).
func saves_root() -> String:
	if not has_identity():
		return ""
	return base_root.path_join(identity_id)


static func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	for sub in dir.get_directories():
		_remove_dir(path.path_join(sub))
	DirAccess.remove_absolute(path)


## Solo nombres de carpeta seguros: un Steam ID (solo dígitos) o un id de desarrollo. Así un id
## raro nunca puede escribir fuera de la carpeta de partidas (p. ej. con "../").
static func is_valid_folder(id: String) -> bool:
	if DevelopmentIdentityProvider.is_valid_id(id):
		return true
	if id.length() < 5 or id.length() > 20:
		return false
	for character in id:
		if not "0123456789".contains(character):
			return false
	return true
