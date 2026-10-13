class_name SaveMigrator
extends RefCounted
## Adapta partidas de versiones anteriores al formato actual (SaveSerializer.VERSION).
## Cada migración pasa de una versión a la siguiente (v1 → v2 → …). Nunca borra datos que no
## entiende: los campos desconocidos se conservan. Antes de migrar, SaveManager guarda una copia
## del archivo original. Una versión más nueva que la del juego no se toca («incompatible»).
##
## Versión 1: la partida única de antes de las ranuras ({version, saved_at, location, game}).
## Versión 2: ranuras, metadatos, mundo y progreso educativo (ver SaveSerializer).


## Devuelve { ok, body, error }. error: "incompatible" (versión futura) o "danado".
static func migrate(version: int, data: Dictionary, slot: int) -> Dictionary:
	if version > SaveSerializer.VERSION:
		return { "ok": false, "body": {}, "error": "incompatible" }
	if version < 1:
		return { "ok": false, "body": {}, "error": "danado" }
	var body := data.duplicate(true)
	if version == 1:
		body = _v1_to_v2(body, slot)
		if body.is_empty():
			return { "ok": false, "body": {}, "error": "danado" }
	return { "ok": true, "body": body, "error": "" }


static func _v1_to_v2(data: Dictionary, slot: int) -> Dictionary:
	var location: Variant = data.get("location")
	var game: Variant = data.get("game")
	if not location is Dictionary or not game is Dictionary:
		return {}
	var flags: Array = game.get("flags", [])
	var body := {
		"meta": {
			"ranura": slot,
			"partida_id": Crypto.new().generate_random_bytes(16).hex_encode(),
			"revision": 1,
			"guardada": int(data.get("saved_at", 0)),
			"tiempo_jugado": 0,
			"version_juego": "",
			"lugar": "",
			"anio": "decimo",
			"capitulo": 1 if flags.has("tutorial_terminado") else 0,
			"nivel": 0,
		},
		"ubicacion": { "escena": String(location.get("scene", "")), "punto": String(location.get("entry", "")) },
		"estado": game,
		"mundo": {},
		"educativo": {},
	}
	# Campos que la versión 1 tenía y la 2 no usa: se conservan aparte.
	for key: String in data:
		if not key in ["version", "saved_at", "location", "game"]:
			body["v1_" + key] = data[key]
	return body
