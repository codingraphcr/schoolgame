class_name TerminalChallenge
extends Resource
## Desafío de una terminal del juego: sus archivos ficticios, qué hay que encontrar, pistas y
## retroalimentación. Se edita en el Inspector y lo usa una TerminalStation.
## Objetivo actual: leer (cat) un archivo concreto. Más tipos de objetivo se agregan aquí.

## Id estable (para el guardado y el Grimorio).
@export var id: StringName = &""
@export var title := "Terminal"
@export_multiline var objective := ""
## Usuario y equipo del prompt (usuario@equipo:~$). La carpeta personal es /home/usuario.
@export var user := "kai"
@export var host := "colegio"
## Texto al abrir la terminal.
@export_multiline var welcome := "Escribe help para ver los comandos."
## Archivos, con rutas relativas a la carpeta personal: { "cuenta/configuracion.txt": "texto" }.
## Las rutas que terminan en "/" son carpetas vacías.
@export var files: Dictionary[String, String] = {}
## Archivo que hay que leer con cat (ruta relativa a la carpeta personal).
@export var goal_file := ""
## Comandos permitidos (vacío = todos los que conoce el intérprete).
@export var allowed_commands: PackedStringArray = []
## Pistas, de la más general a la más concreta (se muestran de una en una).
@export var hints: PackedStringArray = []
## Retroalimentación al resolverlo (qué se aprendió).
@export_multiline var success_text := ""


func create_interpreter() -> CommandInterpreter:
	var interpreter := CommandInterpreter.new(VirtualFileSystem.from_files(files, "/home/" + user))
	interpreter.user = user
	interpreter.host = host
	interpreter.allowed = allowed_commands
	return interpreter


## Si ese comando cumple el objetivo.
func is_goal(interpreter: CommandInterpreter, command: String, target: String) -> bool:
	return command == "cat" and not goal_file.is_empty() and target == interpreter.fs.resolve("~/" + goal_file)
