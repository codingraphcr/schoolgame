@tool
class_name Dialogue
extends Resource
## Un diálogo: una línea por intervención, con el formato "Nombre: texto".
## Las líneas sin "Nombre:" no tienen orador (narración, pensamientos, mensajes de pantalla).
## Las líneas vacías y las que empiezan con # se ignoran (sirven para comentarios).
##
## Ejemplo:
##   Profesor: ¡Kai! Qué bueno que llegas temprano.
##   Kai: Buenos días, profe.
##   # comentario para el equipo
##   (La pantalla parpadea.)

@export_multiline var script_text := ""


## Devuelve las líneas como [{ "speaker": String, "text": String }, ...].
func get_lines() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for raw in script_text.split("\n"):
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var separator := line.find(":")
		# Solo cuenta como orador si el nombre es corto y no tiene espacios dobles (evita cortar
		# frases que contienen ":" en medio del texto).
		if separator > 0 and separator <= 24 and not line.substr(0, separator).contains("  "):
			lines.append({ "speaker": line.substr(0, separator).strip_edges(), "text": line.substr(separator + 1).strip_edges() })
		else:
			lines.append({ "speaker": "", "text": line })
	return lines
