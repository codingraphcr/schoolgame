class_name SaveValidator
extends RefCounted
## Revisa un cuerpo de partida (versión 2) antes de restaurarlo: tipos, rangos y valores
## permitidos. Devuelve "" si sirve, o la primera razón por la que no.
## El JSON de Godot devuelve todos los números como decimales: los enteros se aceptan si no
## tienen parte decimal. Los ids grandes (la partida, el Steam ID) van como texto.

## Ranuras de partida por identidad.
const SLOTS := 3
const YEARS := ["decimo", "undecimo", "duodecimo"]
const SCENES_ROOT := "res://world/zones/"
const ID_CHARS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
const MAX_LIST := 10000


static func validate(body: Dictionary) -> String:
	for section in ["meta", "ubicacion", "estado", "mundo", "educativo"]:
		if not body.get(section) is Dictionary:
			return "falta la sección %s" % section
	var error := _meta(body["meta"])
	if error.is_empty():
		error = _location(body["ubicacion"])
	if error.is_empty():
		error = _state(body["estado"])
	return error


static func _meta(meta: Dictionary) -> String:
	if not is_int(meta.get("ranura"), 1, SLOTS):
		return "ranura inválida"
	if not is_id_hex(meta.get("partida_id"), 32):
		return "id de partida inválido"
	if not is_int(meta.get("revision"), 1, 1_000_000_000):
		return "revisión inválida"
	if not is_int(meta.get("guardada"), 0, 100_000_000_000) or not is_int(meta.get("tiempo_jugado"), 0, 1_000_000_000):
		return "fecha o tiempo inválidos"
	if not meta.get("anio") in YEARS or not is_int(meta.get("capitulo"), 0, 12) or not is_int(meta.get("nivel"), 0, 24):
		return "año, capítulo o nivel inválidos"
	if not is_text(meta.get("lugar"), 60) or not is_text(meta.get("version_juego"), 20):
		return "textos de la ranura inválidos"
	return ""


static func _location(location: Dictionary) -> String:
	var scene: Variant = location.get("escena")
	if typeof(scene) != TYPE_STRING or not String(scene).begins_with(SCENES_ROOT) or not String(scene).ends_with(".tscn") \
			or String(scene).contains("..") or not ResourceLoader.exists(scene):
		return "escena inválida"
	if not is_id(location.get("punto"), 40):
		return "punto de guardado inválido"
	return ""


static func _state(state: Dictionary) -> String:
	for key in ["flags", "found_clues"]:
		if not is_id_list(state.get(key, []), 64):
			return "lista inválida: %s" % key
	# Los comandos aprendidos pueden tener opciones ("ls -a").
	if not is_id_list(state.get("commands", []), 32, " -"):
		return "lista inválida: commands"
	if not state.get("quests", {}) is Dictionary:
		return "misiones inválidas"
	for quest: Variant in state.get("quests", {}):
		if not is_id(quest, 64) or not is_int(state["quests"][quest], -1, 1000):
			return "misión inválida"
	var economy: Variant = state.get("economy", {})
	if not economy is Dictionary or not is_int(economy.get("ecos", 0), 0, 10_000_000) or not is_id_list(economy.get("claimed", []), 128, ":"):
		return "economía inválida"
	var player: Variant = state.get("player", {})
	if not player is Dictionary:
		return "jugador inválido"
	var ranges := {
		"max_masks": [1, 20], "life_fragments": [0, 100], "energy_fragments": [0, 100], "max_energy_cells": [1, 10],
		"dash_level": [0, 3], "nullblade_stage": [0, 4], "aegis_stage": [0, 3], "domain_stage": [0, 5],
	}
	for key: String in ranges:
		if player.has(key) and not is_int(player[key], ranges[key][0], ranges[key][1]):
			return "valor fuera de rango: %s" % key
	for key in ["can_double_jump", "can_wall_jump", "vision_unlocked"]:
		if player.has(key) and typeof(player[key]) != TYPE_BOOL:
			return "valor inválido: %s" % key
	return ""


## Un entero (aunque venga como decimal sin parte decimal) dentro del rango.
static func is_int(value: Variant, low: int, high: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return number == floorf(number) and number >= low and number <= high


static func is_text(value: Variant, max_length: int) -> bool:
	return typeof(value) == TYPE_STRING and String(value).length() <= max_length


## Un id: letras sin tilde, números y _ (y los caracteres extra que se indiquen).
static func is_id(value: Variant, max_length: int, extra := "") -> bool:
	if typeof(value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	var text := String(value)
	if text.is_empty() or text.length() > max_length:
		return false
	for character in text:
		if not ID_CHARS.contains(character) and not extra.contains(character):
			return false
	return true


static func is_id_list(value: Variant, max_length: int, extra := "") -> bool:
	if not value is Array or (value as Array).size() > MAX_LIST:
		return false
	for item: Variant in value:
		if not is_id(item, max_length, extra):
			return false
	return true


static func is_id_hex(value: Variant, length: int) -> bool:
	if typeof(value) != TYPE_STRING or String(value).length() != length:
		return false
	for character in String(value):
		if not "0123456789abcdef".contains(character):
			return false
	return true
