class_name TestServer
extends RefCounted
## Para las pruebas: prende el servidor de cuentas en un puerto libre con una base de datos y una
## carpeta de partidas temporales, y deja Profiles apuntando a él. stop() lo apaga y limpia todo.
## Necesita Python 3 (el servidor solo usa su biblioteca estándar).

var pid := -1
var folder := ""


## Devuelve un TestServer listo, o null si el servidor no arrancó (falta Python).
static func start(tree: SceneTree, name: String) -> TestServer:
	var server := TestServer.new()
	var port := 18000 + randi() % 2000
	server.folder = "user://prueba_%s_%d" % [name, port]
	remove_dir(ProjectSettings.globalize_path(server.folder))
	DirAccess.make_dir_recursive_absolute(server.folder)
	server.pid = LocalServer.start(port, ProjectSettings.globalize_path(server.folder.path_join("cuentas.db")))
	var profiles := tree.root.get_node("Profiles")
	profiles.api.base_url = "http://127.0.0.1:%d" % port
	profiles.cache_root = server.folder.path_join("dispositivo_1")
	profiles.legacy_save = server.folder.path_join("partida_vieja.json")
	if server.pid < 0 or not await LocalServer.wait_until_ready(profiles.api, 15.0):
		print("FAIL no arrancó el servidor de prueba (¿está instalado Python 3?)")
		server.stop(tree)
		return null
	return server


func stop(tree: SceneTree) -> void:
	var profiles := tree.root.get_node("Profiles")
	if profiles.is_logged_in():
		profiles.logout()
	LocalServer.stop(pid)
	# Windows tarda un momento en soltar la base de datos.
	OS.delay_msec(300)
	remove_dir(ProjectSettings.globalize_path(folder))


static func remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	for sub in dir.get_directories():
		remove_dir(path.path_join(sub))
	DirAccess.remove_absolute(path)
