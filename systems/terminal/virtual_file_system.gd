class_name VirtualFileSystem
extends RefCounted
## Sistema de archivos ficticio de una terminal del juego. Vive solo en memoria: nunca lee ni
## escribe archivos del dispositivo. Las carpetas son Dictionary (nombre → contenido) y los
## archivos son String (su texto). Las rutas usan "/" como en Linux; "~" es la carpeta personal.

var home := "/home/kai"
## Carpeta actual (ruta absoluta).
var cwd := "/home/kai"

var _root := {}


## Crea el sistema de archivos a partir de rutas relativas a la carpeta personal:
## { "cuenta/configuracion.txt": "texto", "descargas/": "" } (las que terminan en "/" son carpetas vacías).
static func from_files(files: Dictionary, home_path := "/home/kai") -> VirtualFileSystem:
	var fs := VirtualFileSystem.new()
	fs.home = home_path
	fs.cwd = home_path
	fs._make_dirs(home_path)
	for raw_path: String in files:
		var path := fs.resolve(raw_path)
		if raw_path.ends_with("/"):
			fs._make_dirs(path)
		else:
			fs._make_dirs(path.get_base_dir())
			fs._dir_at(path.get_base_dir())[path.get_file()] = String(files[raw_path])
	return fs


## Convierte una ruta (relativa, absoluta, con ~, . o ..) en una ruta absoluta normalizada.
func resolve(path: String) -> String:
	var full := path.strip_edges()
	if full.is_empty() or full == "~":
		full = home
	elif full.begins_with("~/"):
		full = home + full.substr(1)
	elif not full.begins_with("/"):
		full = cwd + "/" + full
	var parts: PackedStringArray = []
	for part in full.split("/", false):
		if part == ".":
			continue
		if part == "..":
			if not parts.is_empty():
				parts.remove_at(parts.size() - 1)
			continue
		parts.append(part)
	return "/" + "/".join(parts)


func exists(path: String) -> bool:
	return _node_at(resolve(path)) != null


func is_dir(path: String) -> bool:
	return _node_at(resolve(path)) is Dictionary


func is_file(path: String) -> bool:
	return _node_at(resolve(path)) is String


## Nombres dentro de una carpeta, en orden alfabético ([] si no es una carpeta).
func list(path := ".") -> PackedStringArray:
	var node: Variant = _node_at(resolve(path))
	if not node is Dictionary:
		return PackedStringArray()
	var names := PackedStringArray((node as Dictionary).keys())
	names.sort()
	return names


## Texto de un archivo ("" si no existe o es una carpeta).
func read(path: String) -> String:
	var node: Variant = _node_at(resolve(path))
	return node if node is String else ""


## Ruta para mostrar en el prompt: la carpeta personal se abrevia con "~".
func display_path(path: String) -> String:
	if path == home:
		return "~"
	if path.begins_with(home + "/"):
		return "~" + path.substr(home.length())
	return path


func _node_at(absolute: String) -> Variant:
	var node: Variant = _root
	for part in absolute.split("/", false):
		if not node is Dictionary or not (node as Dictionary).has(part):
			return null
		node = node[part]
	return node


func _dir_at(absolute: String) -> Dictionary:
	return _node_at(absolute)


func _make_dirs(absolute: String) -> void:
	var node: Dictionary = _root
	for part in absolute.split("/", false):
		if not node.has(part) or not node[part] is Dictionary:
			node[part] = {}
		node = node[part]
