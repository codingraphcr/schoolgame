class_name LocalServer
extends RefCounted
## Para desarrollar y para las pruebas: prende el servidor de cuentas (server/nullveil_server.py) en
## esta misma computadora. Necesita Python 3 instalado. En el juego publicado no se usa: ahí el
## servidor está en internet (opción "nullveil/servidor/url").

## Prende el servidor y devuelve su proceso (-1 si no se pudo: falta Python).
static func start(port: int, db_path: String) -> int:
	var script := ProjectSettings.globalize_path("res://server/nullveil_server.py")
	for exe in ["python", "py", "python3"]:
		var pid := OS.create_process(exe, [script, "--port", str(port), "--db", db_path])
		if pid > 0:
			return pid
	return -1


static func stop(pid: int) -> void:
	if pid > 0:
		OS.kill(pid)


## Espera hasta que el servidor responda (o se acabe el tiempo). true si respondió.
static func wait_until_ready(api: ApiClient, seconds := 10.0) -> bool:
	var tree := api.get_tree()
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		var reply: Dictionary = await api.get_json("/api/salud")
		if reply["status"] == 200:
			return true
		await tree.create_timer(0.25).timeout
	return false
