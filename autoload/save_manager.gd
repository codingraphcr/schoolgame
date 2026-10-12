extends Node
## Guardado de la partida en el dispositivo (funciona sin conexión).
##
## Guarda todo el progreso (GameState.to_dict: misiones, Ecos, habilidades, comandos, la huella de
## la contraseña, cristales, energía…) y DÓNDE continuar: la sala y la computadora segura
## (SavePoint) donde se guardó. Se guarda en las computadoras seguras.
##
## Escritura segura: primero un archivo temporal, se comprueba que se puede leer y recién entonces
## reemplaza al guardado anterior, que queda como copia de respaldo. Si el principal está dañado,
## se usa la copia. Nunca se pierde la partida por cerrar el juego a mitad de un guardado.
##
## Uso: SaveManager.save_game(escena, id_del_punto) · SaveManager.has_save() · SaveManager.continue_game()

## Versión del formato. Si cambia, _migrate() adapta las partidas viejas.
const VERSION := 1

## Archivo principal (las pruebas usan otro para no tocar la partida del jugador).
var path := "user://partida.json"


func backup_path() -> String:
	return path.get_basename() + ".respaldo.json"


func has_save() -> bool:
	return not load_data().is_empty()


## Guarda la partida. Devuelve false (sin tocar el guardado anterior) si algo falla.
func save_game(scene_path: String, entry: StringName) -> bool:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("SaveManager: escena inválida para guardar (%s)." % scene_path)
		return false
	var data := {
		"version": VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"location": { "scene": scene_path, "entry": String(entry) },
		"game": get_node("/root/GameState").to_dict(),
	}
	var text := JSON.stringify(data, "\t")
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: no se pudo escribir el guardado (%s)." % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(text)
	file.close()
	# Se comprueba lo escrito antes de reemplazar nada.
	if _read(temp).is_empty():
		DirAccess.remove_absolute(_absolute(temp))
		return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup_path()):
			DirAccess.remove_absolute(_absolute(backup_path()))
		DirAccess.rename_absolute(_absolute(path), _absolute(backup_path()))
	var error := DirAccess.rename_absolute(_absolute(temp), _absolute(path))
	return error == OK


## Datos guardados (el principal o, si está dañado, la copia). {} si no hay partida válida.
func load_data() -> Dictionary:
	var data := _read(path)
	if data.is_empty():
		data = _read(backup_path())
	return data


## Carga la partida y lleva a Kai a la computadora segura donde guardó. false si no hay partida.
func continue_game() -> bool:
	var data := load_data()
	if data.is_empty():
		return false
	get_node("/root/GameState").from_dict(data["game"])
	get_node("/root/DigitalVision").reset()
	var location: Dictionary = data["location"]
	get_node("/root/SceneManager").go_to_room(location["scene"], StringName(location["entry"]))
	return true


## Borra la partida y su copia (solo herramientas y pruebas).
func delete_save() -> void:
	for file in [path, backup_path(), path + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(_absolute(file))


## Lee y valida un archivo de guardado. {} si no existe, está dañado o no se puede usar.
func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	# JSON.parse (no parse_string): un archivo dañado no llena la consola de errores.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK or not json.data is Dictionary:
		return {}
	var data := _migrate(json.data)
	var location: Variant = data.get("location")
	if not data.get("game") is Dictionary or not location is Dictionary:
		return {}
	if not ResourceLoader.exists(String(location.get("scene", ""))):
		return {}
	return data


## Adapta partidas de versiones anteriores del formato (hoy solo existe la 1).
func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version < 1 or version > VERSION:
		return {}
	return data


func _absolute(file_path: String) -> String:
	return ProjectSettings.globalize_path(file_path)
