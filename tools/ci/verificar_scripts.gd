extends SceneTree
## Verifica que todos los scripts del juego compilen (lo usa la compilación automática antes de
## exportar). Termina con código 1 si alguno no compila, y dice cuál.
## Ejecutar: godot --headless --path . --script res://tools/ci/verificar_scripts.gd

const FOLDERS := ["res://autoload", "res://characters", "res://components", "res://systems", "res://ui", "res://world", "res://tests"]


func _initialize() -> void:
	var bad := 0
	var total := 0
	for folder in FOLDERS:
		for path in _scripts(folder):
			total += 1
			var script := load(path) as GDScript
			# Las pruebas son SceneTree: no se instancian, solo tienen que cargar.
			if script == null or (not script.can_instantiate() and not path.begins_with("res://tests")):
				bad += 1
				print("NO COMPILA: ", path)
	print("Scripts revisados: %d · con problemas: %d" % [total, bad])
	quit(1 if bad > 0 or total == 0 else 0)


func _scripts(folder: String) -> Array[String]:
	var result: Array[String] = []
	for file in ResourceLoader.list_directory(folder):
		var path := folder.path_join(file)
		if file.ends_with("/"):
			result.append_array(_scripts(path.trim_suffix("/")))
		elif file.ends_with(".gd"):
			result.append(path)
	return result
