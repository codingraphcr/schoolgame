class_name AutoSave
extends Node
## Guardado automático de la partida en juego (lo crea SaveManager). Ver
## docs/arquitectura/SISTEMA_USUARIOS_STEAM.md, sección 7.
##
## Cuándo pide guardar: al completar un paso o una misión (también al cambiar de capítulo, que llega
## por una misión), al obtener una habilidad o mejora permanente, al cobrar una recompensa única
## (terminales, desafíos, jefes, fragmentos) y al salir al menú.
##
## Solo guarda si es seguro (is_safe): hay una ranura activa, Kai está en una sala, vivo, en el suelo,
## sin reaparecer, con control (no hay diálogo ni cinemática) y no hay transición de escena, pausa ni
## nada en el grupo «guardado_bloqueado» (peleas, persecuciones…). Si no es seguro, el pedido queda
## pendiente y se reintenta. Siempre guarda un punto de reaparición válido (Room.save_point_id()):
## nunca la posición exacta (podría ser una caída o el medio de un ataque).

signal autosaved(reason: String)

## Grupo de los nodos que impiden guardar mientras existen y están en él (p. ej. una pelea de jefe).
const BLOCK_GROUP := &"guardado_bloqueado"
const RETRY_SECONDS := 0.5

var enabled := true
## Razón del guardado pendiente ("" = ninguno).
var pending := ""

var _abilities := {}
var _quiet := false
var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = RETRY_SECONDS
	_timer.timeout.connect(_try)
	add_child(_timer)
	var game_state := get_node("/root/GameState")
	game_state.quest_step_changed.connect(func(_quest: StringName) -> void: request("mision"))
	game_state.quest_completed.connect(func(_quest: StringName) -> void: request("mision"))
	game_state.progress_changed.connect(_on_progress_changed)
	get_node("/root/Economy").reward_claimed.connect(func(_id: StringName) -> void: request("recompensa"))
	resync()


## Mientras se carga o se empieza una partida, los cambios no son «logros» del jugador.
func quiet(on: bool) -> void:
	_quiet = on
	if not on:
		resync()


## Toma la foto actual de las habilidades (después de cargar o empezar una partida).
func resync() -> void:
	_abilities = _snapshot()
	pending = ""
	_timer.stop()


## Pide un guardado automático; se hace en cuanto sea seguro.
func request(reason: String) -> void:
	if not enabled or _quiet or get_node("/root/SaveManager").active_slot == 0:
		return
	pending = reason
	_try()


## Guarda ya si es seguro (p. ej. al salir al menú). true si guardó.
func save_now(reason: String) -> bool:
	if not enabled or get_node("/root/SaveManager").active_slot == 0:
		return false
	pending = reason
	return _try()


## Si ahora se puede guardar sin dejar a Kai en un estado raro. { ok, reason }.
func is_safe() -> Dictionary:
	var saves := get_node("/root/SaveManager")
	if saves.active_slot == 0:
		return { "ok": false, "reason": "sin_ranura" }
	if get_node("/root/SceneManager").is_changing():
		return { "ok": false, "reason": "transicion" }
	if get_tree().paused:
		return { "ok": false, "reason": "pausa" }
	var room := get_tree().current_scene as Room
	if room == null or room.player == null or room.scene_file_path.is_empty():
		return { "ok": false, "reason": "sin_sala" }
	var player := room.player
	if player.health.is_dead() or player.damage.is_respawning:
		return { "ok": false, "reason": "derrota" }
	if not player.is_on_floor():
		return { "ok": false, "reason": "en_el_aire" }
	if player.controls_locked:
		return { "ok": false, "reason": "cinematica" }
	var box := DialogueBox.find(room)
	if box and box.is_playing():
		return { "ok": false, "reason": "dialogo" }
	for node in get_tree().get_nodes_in_group(BLOCK_GROUP):
		if node.is_inside_tree():
			return { "ok": false, "reason": "bloqueado" }
	return { "ok": true, "reason": "" }


func _try() -> bool:
	if pending.is_empty():
		_timer.stop()
		return false
	if not is_safe()["ok"]:
		if _timer.is_stopped():
			_timer.start()
		return false
	_timer.stop()
	var room := get_tree().current_scene as Room
	var reason := pending
	pending = ""
	var ok: bool = get_node("/root/SaveManager").save_game(room.scene_file_path, room.save_point_id())
	if ok:
		autosaved.emit(reason)
	return ok


func _on_progress_changed() -> void:
	if _quiet:
		return
	var now := _snapshot()
	for key: String in now:
		if float(now[key]) > float(_abilities.get(key, 0)):
			_abilities = now
			request("habilidad")
			return
	_abilities = now


## Habilidades y mejoras permanentes (todo lo que solo puede subir).
func _snapshot() -> Dictionary:
	var gs := get_node("/root/GameState")
	return {
		"dash": gs.dash_level, "doble_salto": int(gs.can_double_jump), "pared": int(gs.can_wall_jump),
		"vision": int(gs.vision_unlocked), "nullblade": gs.nullblade_stage, "aegis": gs.aegis_stage,
		"dominio": gs.domain_stage, "cristales": gs.max_masks, "energia": gs.max_energy_cells,
	}
