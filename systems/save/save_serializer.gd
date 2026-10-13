class_name SaveSerializer
extends RefCounted
## Formato de un archivo de partida (versión 2): texto, sin objetos de Godot ni código.
##
##   línea 1:  {"formato":"nullveil-partida","integridad":"<sha256 del cuerpo>","save_version":2}
##   resto:    el cuerpo en JSON (meta, ubicacion, estado, mundo, educativo)
##
## La integridad es la huella SHA-256 del texto del cuerpo tal como se escribió: detecta archivos
## cortados o dañados. No impide que alguien edite el archivo a propósito (eso no se puede evitar
## en un archivo local); por eso SaveValidator además revisa tipos y rangos.
## Los archivos de la versión 1 (antes de las ranuras) son un solo JSON: unpack() los reconoce.

const FORMAT := "nullveil-partida"
const VERSION := 2
## Una partida pesa pocos KB: un archivo más grande se rechaza sin leerlo entero.
const MAX_BYTES := 2_000_000


static func pack(body: Dictionary) -> String:
	var text := JSON.stringify(body, "\t")
	var header := { "formato": FORMAT, "save_version": VERSION, "integridad": text.sha256_text() }
	return JSON.stringify(header) + "\n" + text


## Lee el texto de un archivo. Devuelve { ok, version, body, error }.
## error: "danado" (no se puede leer o la huella no coincide) o "" si está bien.
static func unpack(text: String) -> Dictionary:
	var bad := { "ok": false, "version": 0, "body": {}, "error": "danado" }
	if text.is_empty() or text.length() > MAX_BYTES:
		return bad
	var newline := text.find("\n")
	var json := JSON.new()
	if newline > 0 and json.parse(text.substr(0, newline)) == OK and json.data is Dictionary \
			and json.data.get("formato") == FORMAT:
		var header: Dictionary = json.data
		var body_text := text.substr(newline + 1)
		if typeof(header.get("integridad")) != TYPE_STRING or body_text.sha256_text() != header["integridad"]:
			return bad
		if json.parse(body_text) != OK or not json.data is Dictionary:
			return bad
		var version: Variant = header.get("save_version")
		if typeof(version) not in [TYPE_INT, TYPE_FLOAT] or float(version) != floorf(float(version)):
			return bad
		return { "ok": true, "version": int(version), "body": json.data, "error": "" }
	# Versión 1: todo el archivo es un JSON con "version".
	if json.parse(text) == OK and json.data is Dictionary and typeof(json.data.get("version")) in [TYPE_INT, TYPE_FLOAT]:
		return { "ok": true, "version": int(json.data["version"]), "body": json.data, "error": "" }
	return bad
