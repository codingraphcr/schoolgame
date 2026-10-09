@tool
class_name Dialogue
extends Resource
## Un diálogo: una línea por intervención, con el formato "Nombre: texto".
## Opcionalmente, una expresión entre corchetes para el retrato: "Nombre [serio]: texto".
## Las líneas sin "Nombre:" no tienen orador (narración, pensamientos, mensajes de pantalla).
## Las líneas vacías y las que empiezan con # se ignoran (sirven para comentarios).
## Los retratos, títulos y colores de cada personaje están en data/characters/ (DialogueCharacter).
##
## Ejemplo:
##   Prof. Álvarez: ¡Kai! Qué bueno que llegas temprano.
##   Kai: Buenos días, profe.
##   Prof. Álvarez [preocupado]: La computadora del laboratorio está rarísima.
##   # comentario para el equipo
##   (La pantalla parpadea.)

@export_multiline var script_text := ""


## Devuelve las líneas como [{ "speaker": String, "expression": String, "text": String }, ...].
func get_lines() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for raw in script_text.split("\n"):
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var separator := line.find(":")
		# Solo cuenta como orador si el nombre es corto y no tiene espacios dobles (evita cortar
		# frases que contienen ":" en medio del texto).
		if separator > 0 and separator <= 40 and not line.substr(0, separator).contains("  "):
			var speaker := line.substr(0, separator).strip_edges()
			var expression := ""
			var bracket := speaker.find("[")
			if bracket > 0 and speaker.ends_with("]"):
				expression = speaker.substr(bracket + 1, speaker.length() - bracket - 2).strip_edges()
				speaker = speaker.substr(0, bracket).strip_edges()
			lines.append({ "speaker": speaker, "expression": expression, "text": line.substr(separator + 1).strip_edges() })
		else:
			lines.append({ "speaker": "", "expression": "", "text": line })
	return lines
