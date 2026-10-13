class_name UserDataMigration
extends RefCounted
## El juego guarda sus datos en una carpeta propia (%APPDATA%\Nullveil en Windows: opción
## application/config/custom_user_dir_name). Antes estaban en la carpeta que arma Godot con el nombre
## del juego (%APPDATA%\Godot\app_userdata\Nullveil- Beyond the Firewall). Al arrancar, si la carpeta
## nueva todavía no tiene datos y la vieja sí, se copian: partidas, opciones e identidad de desarrollo.
## La carpeta vieja no se toca (queda como copia; se puede borrar a mano). Nunca pisa datos nuevos.

const OLD_FOLDER := "Godot/app_userdata/Nullveil- Beyond the Firewall"
## Lo que se copia (carpetas terminan en "/").
const ITEMS := ["partidas/", "ajustes.cfg", "identidad_desarrollo.cfg"]
const MARKER := "migrado_desde_app_userdata.txt"


## La carpeta vieja en este equipo (absoluta).
static func old_dir() -> String:
	return OS.get_data_dir().path_join(OLD_FOLDER)


## Copia los datos de old_abs a new_abs si corresponde. Devuelve true si copió algo.
static func migrate(old_abs: String, new_abs: String) -> bool:
	if old_abs.is_empty() or old_abs.simplify_path() == new_abs.simplify_path() or not DirAccess.dir_exists_absolute(old_abs):
		return false
	# Si la carpeta nueva ya tiene datos del juego, no se mezcla nada.
	for item in ITEMS:
		var target := new_abs.path_join(item.trim_suffix("/"))
		if FileAccess.file_exists(target) or DirAccess.dir_exists_absolute(target):
			return false
	var copied := false
	for item in ITEMS:
		var source := old_abs.path_join(item.trim_suffix("/"))
		var target := new_abs.path_join(item.trim_suffix("/"))
		if item.ends_with("/") and DirAccess.dir_exists_absolute(source):
			copied = _copy_dir(source, target) or copied
		elif FileAccess.file_exists(source):
			DirAccess.make_dir_recursive_absolute(new_abs)
			copied = DirAccess.copy_absolute(source, target) == OK or copied
	if copied:
		var marker := FileAccess.open(new_abs.path_join(MARKER), FileAccess.WRITE)
		if marker:
			marker.store_string("Datos copiados desde %s el %s.\nLa carpeta vieja no se borró.\n" % [old_abs, Time.get_datetime_string_from_system()])
	return copied


static func _copy_dir(source: String, target: String) -> bool:
	var dir := DirAccess.open(source)
	if dir == null:
		return false
	DirAccess.make_dir_recursive_absolute(target)
	var copied := false
	for file in dir.get_files():
		copied = DirAccess.copy_absolute(source.path_join(file), target.path_join(file)) == OK or copied
	for sub in dir.get_directories():
		copied = _copy_dir(source.path_join(sub), target.path_join(sub)) or copied
	return copied
