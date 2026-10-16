class_name Room
extends Node2D
## Sala del mundo. Calcula los límites de la cámara a partir del TileMapLayer y coloca al jugador
## en el punto de aparición, aplicándole el progreso de la partida (GameState). Si el jugador cae
## fuera, cuenta como peligro (1 máscara y vuelta al último suelo seguro). Si muere, pierde una
## parte de los Ecos y reaparece en el punto de control con las máscaras llenas.
## El nodo raíz de cada sala usa filtro Nearest para que el pixel art se vea nítido.

## Kai reapareció en el punto de control después de morir.
signal player_respawned

@export var tile_layer: TileMapLayer
@export var player: Player
@export var camera: GameCamera
@export var spawn_point: Marker2D
## Dónde reaparece el jugador al morir (banco o RestorePoint). Si está vacío, se usa spawn_point.
@export var checkpoint: Node2D
## Tamaño de la sala si no tiene TileMapLayer (p. ej. el interior de una computadora).
@export var room_size := Rect2()
## Color del dibujo de Kai en esta sala (p. ej. celeste: su alma digital dentro de una computadora).
@export var player_tint := Color.WHITE
## Distancia (px) bajo el borde inferior de la sala a partir de la cual el jugador reaparece.
@export var fall_limit_margin := 64.0
## Integridad que quita caer al vacío (Kai vuelve a la última plataforma segura).
@export var fall_damage := 1.0
## Sonido de los pasos de Kai en esta sala (step_school en el colegio, step_digital en una computadora).
@export var footstep: StringName = &"step_school"
## Música de la sala (vacío = sigue la que estaba). Ver Music.
@export var music_track: StringName = &""

var bounds: Rect2
## Id de esta sala en el mapa (World); vacío si la escena no está en el mapa.
var room_id: StringName = &""
## Entrada (RoomEntry.id) por la que llegó Kai: un punto de reaparición válido para guardar.
var arrival_entry: StringName = &""


func _ready() -> void:
	bounds = _compute_bounds()
	if music_track != &"":
		Music.play(music_track)
	if camera:
		camera.set_limits(bounds)
	var world := get_node_or_null("/root/World")
	if world and not scene_file_path.is_empty():
		room_id = world.enter(scene_file_path, _scene_manager().take_pending_room())
	var game_state := _game_state()
	# Queda anotado que Kai estuvo en esta sala (el mapa del Grimorio lo usa).
	if game_state and not scene_file_path.is_empty():
		game_state.set_flag(StringName("visitada_" + scene_file_path.get_file().get_basename()))
	if player and game_state:
		player.apply_progress(game_state, true)
		# Las máscaras se conservan entre salas (cambiar de sala no cura).
		if game_state.current_masks >= 0.0:
			player.health.current = clampf(game_state.current_masks, 1.0, player.health.max_health)
			player.health.health_changed.emit(player.health.current, player.health.max_health)
		# La energía también se conserva.
		if game_state.current_energy >= 0.0:
			player.set_energy(game_state.current_energy)
		game_state.progress_changed.connect(_on_progress_changed)
	if player:
		(player.get_node("Visual") as CanvasItem).modulate = player_tint
		player.damage.died.connect(_on_player_died)
		player.damage.hurt.connect(_on_player_hurt)
		player.damage.hazard_respawned.connect(_snap_camera)
	_place_player()
	# Desde el Capítulo 3, Aegis acompaña a Kai en todas las salas.
	if player and game_state and AegisCompanion.is_active(game_state):
		spawn_companion()


func _exit_tree() -> void:
	var game_state := _game_state()
	if player and game_state:
		game_state.current_masks = player.health.current
		game_state.current_energy = player.energy


func _process(delta: float) -> void:
	# Tiempo jugado: solo mientras se juega en una sala (con el juego en pausa este nodo no corre).
	var game_state := _game_state()
	if game_state:
		game_state.play_time += delta


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y > bounds.end.y + fall_limit_margin:
		player.damage.fall_out_of_bounds(fall_damage)


## Q enciende o apaga la Visión Digital (solo si ya se descubrió; si no, no hace nada).
## Esc vuelve al menú principal (temporal, hasta que exista el menú de pausa).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("vision") and not player.controls_locked:
		get_viewport().set_input_as_handled()
		get_node("/root/DigitalVision").toggle()
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		# Al salir por el menú se guarda (si es seguro).
		var saves := get_node_or_null("/root/SaveManager")
		if saves:
			saves.auto_save.save_now("salir")
		var scene_manager := _scene_manager()
		scene_manager.change_scene(scene_manager.MAIN_MENU)


## Agrega a Aegis junto a Kai (si todavía no está). Lo llama la sala al cargar y la escena en que Aegis decide acompañarlo.
func spawn_companion() -> AegisCompanion:
	for node in find_children("*", "AegisCompanion", true, false):
		return node as AegisCompanion
	var companion := AegisCompanion.new()
	companion.name = "AegisCompanion"
	companion.player = player
	add_child(companion)
	return companion


## Al cargar la sala: por la entrada desde la que se llega, o en el punto de aparición.
func _place_player() -> void:
	var entry_id: StringName = _scene_manager().take_pending_entry()
	var entry: RoomEntry = null
	if entry_id != &"":
		entry = _find_entry(entry_id)
	if entry == null and player != null:
		# Al continuar una partida: la computadora segura donde se guardó.
		var save_point := _find_save_point(entry_id)
		if save_point:
			arrival_entry = save_point.save_id
			player.teleport_to(save_point.global_position)
			checkpoint = save_point
			save_point.active = true
			_snap_camera()
			return
	if entry == null or player == null:
		respawn_player()
		return
	arrival_entry = entry.id
	player.teleport_to(entry.global_position)
	player.face(entry.facing)
	_snap_camera()
	if entry.arrival_effect == "materialize":
		_materialize_player()


## Llegada desde una computadora: se cierra la pantalla de carga y Kai se arma desde píxeles.
func _materialize_player() -> void:
	player.controls_locked = true
	LoadingScreen.dismiss_all(get_tree())
	await DigitalDive.materialize(player)
	player.controls_locked = false


## Dónde reaparecer si se guarda ahora: la computadora segura activa o la entrada por la que llegó
## Kai (nunca su posición exacta). Vacío = el punto de aparición de la sala.
func save_point_id() -> StringName:
	if checkpoint is SavePoint:
		return (checkpoint as SavePoint).save_id
	return arrival_entry


func _find_save_point(save_id: StringName) -> SavePoint:
	if save_id == &"":
		return null
	for node in find_children("*", "SavePoint", true, false):
		if (node as SavePoint).save_id == save_id:
			return node
	return null


func _find_entry(entry_id: StringName) -> RoomEntry:
	for node in find_children("*", "RoomEntry", true, false):
		if (node as RoomEntry).id == entry_id:
			return node
	if _find_save_point(entry_id) == null:
		push_warning("Room: no existe la entrada '%s'; se usa el punto de aparición." % entry_id)
	return null


func respawn_player() -> void:
	if player == null or spawn_point == null:
		return
	player.teleport_to(spawn_point.global_position)
	_snap_camera()


func _on_player_died() -> void:
	# Pierde Ecos (10 %, máximo 100; nada durante el tutorial). El HUD muestra cuántos.
	var economy := get_node_or_null("/root/Economy")
	if economy:
		economy.apply_death_penalty()
	# Muerte y reaparición con la secuencia de la hoja de Ariel (desintegración, "CONEXIÓN PERDIDA...").
	await DeathSequence.play(player, _respawn_at_checkpoint)


func _on_progress_changed() -> void:
	if player:
		player.apply_progress(_game_state())


func _respawn_at_checkpoint() -> void:
	var target: Node2D = checkpoint if checkpoint else spawn_point
	if target:
		player.teleport_to(target.global_position)
	player.damage.revive()
	_snap_camera()
	player_respawned.emit()


func _on_player_hurt(_hit: HitData) -> void:
	if camera:
		camera.shake(3.0, 0.25)


func _snap_camera() -> void:
	if camera:
		camera.snap_to_target()


func _compute_bounds() -> Rect2:
	if (tile_layer == null or tile_layer.tile_set == null) and room_size.has_area():
		return room_size
	if tile_layer == null or tile_layer.tile_set == null:
		push_warning("Room: falta el TileMapLayer; la cámara no tendrá límites.")
		return Rect2(-100000, -100000, 200000, 200000)
	var used := tile_layer.get_used_rect()
	var tile_size := Vector2(tile_layer.tile_set.tile_size)
	var top_left := tile_layer.to_global(tile_layer.map_to_local(used.position) - tile_size / 2.0)
	return Rect2(top_left, Vector2(used.size) * tile_size)


## Los autoloads se obtienen por ruta (no por nombre global) para que este script también compile
## en las pruebas de línea de comandos, donde los autoloads se registran después.
func _scene_manager() -> Node:
	return get_node("/root/SceneManager")


func _game_state() -> Node:
	return get_node_or_null("/root/GameState")
