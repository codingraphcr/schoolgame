class_name ProfileStats
extends RefCounted
## Resumen del perfil del jugador para «Mi perfil»: junta lo que dicen las ranuras de la identidad
## actual (SaveManager). Solo lee: nunca cambia una partida. No incluye datos privados de la cuenta.
##
## Tiempo total = suma de las 3 ranuras. El resto (año, capítulo, Ecos, habilidades, porcentajes,
## estadísticas educativas) es de la partida más reciente (la última usada en este equipo).

const NULLBLADE_STAGES := ["", "Nullblade.exe", "Nullblade.zero", "Nullblade.void", "Nullblade.max"]
const AEGIS_STAGES := ["", "Aegis Pulse", "Aegis Bridge", "Aegis Sync"]


static func compute(saves: Node) -> Dictionary:
	var total_time := 0
	var slots_used := 0
	var last_saved := 0
	for slot in range(1, SaveManager.SLOTS + 1):
		var info: Dictionary = saves.slot_info(slot)
		if info["estado"] in ["ok", "recuperada"]:
			slots_used += 1
			total_time += int(info["meta"].get("tiempo_jugado", 0))
			last_saved = maxi(last_saved, int(info["meta"].get("guardada", 0)))
	var result := {
		"tiempo_total": total_time,
		"partidas": slots_used,
		"ultimo_guardado": last_saved,
		"ranura": 0,
		"meta": {},
		"ecos": 0,
		"habilidades": PackedStringArray(),
		"comandos": 0,
		"terminales": 0,
		"desafios": 0,
		"logros": PackedStringArray(),
	}
	var slot: int = saves.last_slot()
	if slot == 0:
		return result
	var body: Dictionary = saves.read_slot(slot)
	if body.is_empty():
		return result
	var state: Dictionary = body["estado"]
	var learning: Dictionary = body.get("educativo", {})
	result["ranura"] = slot
	result["meta"] = body["meta"]
	result["ecos"] = int((state.get("economy", {}) as Dictionary).get("ecos", 0))
	result["habilidades"] = abilities(state.get("player", {}))
	result["comandos"] = (state.get("commands", []) as Array).size()
	result["terminales"] = (learning.get("terminales", []) as Array).size()
	result["desafios"] = (learning.get("desafios", []) as Array).size()
	return result


## Nombres de las habilidades y del equipo que tiene la partida (en orden de la historia).
static func abilities(player: Dictionary) -> PackedStringArray:
	var names: PackedStringArray = []
	var nullblade := clampi(int(player.get("nullblade_stage", 0)), 0, NULLBLADE_STAGES.size() - 1)
	if nullblade > 0:
		names.append(NULLBLADE_STAGES[nullblade])
	if bool(player.get("vision_unlocked", false)):
		names.append("Visión Digital")
	if bool(player.get("immersion_unlocked", false)):
		names.append("Inmersión Digital")
	if int(player.get("dash_level", 0)) > 0:
		names.append("Dash" if int(player["dash_level"]) == 1 else "Dash nivel %d" % int(player["dash_level"]))
	if bool(player.get("can_double_jump", false)):
		names.append("Doble salto")
	if bool(player.get("can_wall_jump", false)):
		names.append("Salto en pared")
	var aegis := clampi(int(player.get("aegis_stage", 0)), 0, AEGIS_STAGES.size() - 1)
	if aegis > 0:
		names.append(AEGIS_STAGES[aegis])
	if int(player.get("domain_stage", 0)) > 0:
		names.append("Dominio Nulo %s" % ["I", "II", "III", "IV", "V"][clampi(int(player["domain_stage"]) - 1, 0, 4)])
	return names
