class_name CommandInterpreter
extends RefCounted
## Intérprete de la terminal simulada. Solo conoce una lista de comandos permitidos y trabaja sobre
## un VirtualFileSystem: no ejecuta programas del dispositivo ni lee sus archivos.
## Los comandos y mensajes imitan a Linux (bash) para que lo aprendido sirva en una terminal real.
##
## execute() devuelve { "output": String, "ok": bool, "clear": bool }. Cada comando que funciona
## emite command_run (comando, argumentos, ruta absoluta afectada o "").

signal command_run(command: String, args: PackedStringArray, target: String)

## Descripción corta de cada comando (para "help").
const COMMANDS := {
	"help": "muestra los comandos disponibles",
	"pwd": "muestra en qué carpeta estás",
	"ls": "lista lo que hay en una carpeta",
	"cd": "entra a una carpeta (cd .. vuelve atrás, cd ~ a tu carpeta personal)",
	"cat": "muestra el contenido de un archivo",
	"clear": "limpia la pantalla",
	"history": "muestra los comandos que escribiste",
}

var fs: VirtualFileSystem
var user := "kai"
var host := "colegio"
## Comandos que se pueden usar en esta terminal (vacío = todos los de COMMANDS).
var allowed: PackedStringArray = []
var history: PackedStringArray = []


func _init(file_system: VirtualFileSystem = null) -> void:
	fs = file_system if file_system else VirtualFileSystem.new()


## Texto del prompt, como en Linux: kai@pc-profesor:~/cuenta$
func prompt() -> String:
	return "%s@%s:%s$" % [user, host, fs.display_path(fs.cwd)]


func is_available(command: String) -> bool:
	return COMMANDS.has(command) and (allowed.is_empty() or allowed.has(command))


func available_commands() -> PackedStringArray:
	var names: PackedStringArray = []
	for command: String in COMMANDS:
		if is_available(command):
			names.append(command)
	return names


func execute(line: String) -> Dictionary:
	var words := line.strip_edges().split(" ", false)
	if words.is_empty():
		return _result("")
	history.append(line.strip_edges())
	var command := words[0]
	var args := words.slice(1)
	if not COMMANDS.has(command):
		return _error("%s: orden no encontrada · escribe help para ver los comandos" % command)
	if not is_available(command):
		return _error("%s: todavía no puedes usar este comando aquí" % command)
	match command:
		"help":
			return _ok(command, args, "", _help())
		"pwd":
			return _ok(command, args, fs.cwd, fs.cwd)
		"ls":
			return _ls(args)
		"cd":
			return _cd(args)
		"cat":
			return _cat(args)
		"clear":
			var result := _ok(command, args, "", "")
			result["clear"] = true
			return result
		"history":
			var lines: PackedStringArray = []
			for i in history.size():
				lines.append("%4d  %s" % [i + 1, history[i]])
			return _ok(command, args, "", "\n".join(lines))
	return _error("%s: orden no encontrada" % command)


## Completa la última palabra (comando o ruta). Devuelve la línea completada, o la misma si no hay
## una única opción.
func complete(line: String) -> String:
	var words := line.split(" ")
	var last := words[words.size() - 1]
	var options: PackedStringArray = []
	if words.size() == 1:
		for command in available_commands():
			if command.begins_with(last):
				options.append(command + " ")
	else:
		var slash := last.rfind("/")
		var base := last.substr(0, slash + 1)
		var partial := last.substr(slash + 1)
		var folder := base if not base.is_empty() else "."
		for name in fs.list(folder):
			if name.begins_with(partial):
				options.append(base + name + ("/" if fs.is_dir(base + name) else " "))
	if options.size() != 1:
		return line
	words[words.size() - 1] = options[0]
	return " ".join(words)


func _ls(args: PackedStringArray) -> Dictionary:
	var target := args[0] if not args.is_empty() else "."
	var path := fs.resolve(target)
	if not fs.exists(path):
		return _error("ls: no se puede acceder a '%s': No existe el archivo o el directorio" % target)
	if fs.is_file(path):
		return _ok("ls", args, path, target)
	var names: PackedStringArray = []
	for name in fs.list(path):
		names.append(name + "/" if fs.is_dir(path + "/" + name) else name)
	return _ok("ls", args, path, "  ".join(names))


func _cd(args: PackedStringArray) -> Dictionary:
	var target := args[0] if not args.is_empty() else "~"
	var path := fs.resolve(target)
	if not fs.exists(path):
		return _error("cd: %s: No existe el archivo o el directorio" % target)
	if not fs.is_dir(path):
		return _error("cd: %s: No es un directorio" % target)
	fs.cwd = path
	return _ok("cd", args, path, "")


func _cat(args: PackedStringArray) -> Dictionary:
	if args.is_empty():
		return _error("cat: falta el nombre del archivo · ejemplo: cat notas.txt")
	var path := fs.resolve(args[0])
	if not fs.exists(path):
		return _error("cat: %s: No existe el archivo o el directorio" % args[0])
	if fs.is_dir(path):
		return _error("cat: %s: Es un directorio" % args[0])
	return _ok("cat", args, path, fs.read(path).strip_edges(false, true))


func _help() -> String:
	var lines: PackedStringArray = ["Comandos disponibles:"]
	for command in available_commands():
		lines.append("  %-8s %s" % [command, COMMANDS[command]])
	return "\n".join(lines)


func _ok(command: String, args: PackedStringArray, target: String, output: String) -> Dictionary:
	command_run.emit(command, args, target)
	return _result(output)


func _result(output: String) -> Dictionary:
	return { "output": output, "ok": true, "clear": false }


func _error(message: String) -> Dictionary:
	return { "output": message, "ok": false, "clear": false }
