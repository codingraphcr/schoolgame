class_name TerminalChallenge
extends Resource
## Desafío de una terminal del juego: sus archivos ficticios, qué hay que encontrar, pistas y
## retroalimentación. Se edita en el Inspector y lo usa una TerminalStation.
## Objetivo actual: leer (cat) un archivo concreto. Más tipos de objetivo se agregan aquí.
## Puede tener una carpeta protegida: sus archivos ocultos piden la contraseña de su dueño, que se
## elige entre password_options (cada opción explica por qué sí o por qué no).

## Id estable (para el guardado y el Grimorio).
@export var id: StringName = &""
@export var title := "Terminal"
@export_multiline var objective := ""
## Usuario y equipo del prompt (usuario@equipo:~$). La carpeta personal es /home/usuario.
@export var user := "kai"
@export var host := "colegio"
## Texto al abrir la terminal.
@export_multiline var welcome := "Escribe help para ver los comandos."
## Archivos, con rutas relativas a la carpeta personal: { "cuenta/configuracion.txt": "texto" }
## (o absolutas: "/home/otro/notas.txt"). Las que terminan en "/" son carpetas vacías. Los nombres
## que empiezan con «.» son ocultos: solo se ven con ls -a.
@export var files: Dictionary[String, String] = {}
## Archivo que hay que leer con cat (relativo a la carpeta personal, o absoluto).
@export var goal_file := ""
## Comandos permitidos (vacío = todos los que conoce el intérprete).
@export var allowed_commands: PackedStringArray = []
## Pistas, de la más general a la más concreta (se muestran de una en una).
@export var hints: PackedStringArray = []
## Retroalimentación al resolverlo (qué se aprendió).
@export_multiline var success_text := ""
## Ecos al resolverlo por primera vez (-1 = sorteado entre los de terminal en EconomyConfig).
@export var ecos_reward := -1

@export_group("Carpeta protegida")
## Carpeta (absoluta o con ~) cuyo contenido oculto pide contraseña. Vacío = ninguna.
@export var protected_folder := ""
## Texto al pedir la contraseña.
@export_multiline var password_prompt := ""
## Las contraseñas entre las que se elige (una correcta), con su explicación.
@export var password_options: Array[ChoiceOption] = []


func create_interpreter() -> CommandInterpreter:
	var interpreter := CommandInterpreter.new(VirtualFileSystem.from_files(files, "/home/" + user))
	interpreter.user = user
	interpreter.host = host
	interpreter.allowed = allowed_commands
	if not protected_folder.is_empty():
		interpreter.protected_dirs = [interpreter.fs.resolve(protected_folder)]
	return interpreter


## Si ese comando cumple el objetivo.
func is_goal(interpreter: CommandInterpreter, command: String, target: String) -> bool:
	if command != "cat" or goal_file.is_empty():
		return false
	return target == interpreter.fs.resolve(goal_file if goal_file.begins_with("/") else "~/" + goal_file)
