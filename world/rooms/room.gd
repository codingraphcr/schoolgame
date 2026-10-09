class_name Room
extends Node2D
## Sala del mundo. Calcula los límites de la cámara a partir del TileMapLayer y coloca al jugador
## en el punto de aparición, aplicándole el progreso de la partida (GameState). Si el jugador cae
## fuera, cuenta como peligro (1 máscara y vuelta al último suelo seguro). Si muere, pierde una
## parte de los créditos y reaparece en el punto de control con las máscaras llenas.
## El nodo raíz de cada sala usa filtro Nearest para que el pixel art se vea nítido.

@export var tile_layer: TileMapLayer
@export var player: Player
@export var camera: GameCamera
@export var spawn_point: Marker2D
## Dónde reaparece el jugador al morir (banco). Si está vacío, se usa spawn_point.
@export var checkpoint: Marker2D
## Tamaño de la sala si no tiene TileMapLayer (p. ej. el interior de una computadora).
@export var room_size := Rect2()
## Color del dibujo de Kai en esta sala (p. ej. celeste: su alma digital dentro de una computadora).
@export var player_tint := Color.WHITE
## Distancia (px) bajo el borde inferior de la sala a partir de la cual el jugador reaparece.
@export var fall_limit_margin := 64.0

var bounds: Rect2


func _ready() -> void:
	bounds = _compute_bounds()
	if camera:
		camera.set_limits(bounds)
	var game_state := _game_state()
	if player and game_state:
		player.apply_progress(game_state, true)
		# Las máscaras se conservan entre salas (cambiar de sala no cura).
		if game_state.current_masks >= 0.0:
			player.health.current = clampf(game_state.current_masks, 1.0, player.health.max_health)
			player.health.health_changed.emit(player.health.current, player.health.max_health)
		game_state.progress_changed.connect(_on_progress_changed)
	if player:
		(player.get_node("Visual") as CanvasItem).modulate = player_tint
		player.damage.died.connect(_on_player_died)
		player.damage.hurt.connect(_on_player_hurt)
		player.damage.hazard_respawned.connect(_snap_camera)
	_place_player()


func _exit_tree() -> void:
	var game_state := _game_state()
	if player and game_state:
		game_state.current_masks = player.health.current


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y > bounds.end.y + fall_limit_margin:
		player.damage.fall_out_of_bounds()


## Q enciende o apaga la Visión Digital (solo si ya se descubrió; si no, no hace nada).
## Esc vuelve al menú principal (temporal, hasta que exista el menú de pausa).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("vision") and not player.controls_locked:
		get_viewport().set_input_as_handled()
		get_node("/root/DigitalVision").toggle()
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		var scene_manager := _scene_manager()
		scene_manager.change_scene(scene_manager.MAIN_MENU)


## Al cargar la sala: por la entrada desde la que se llega, o en el punto de aparición.
func _place_player() -> void:
	var entry_id: StringName = _scene_manager().take_pending_entry()
	var entry: RoomEntry = null
	if entry_id != &"":
		entry = _find_entry(entry_id)
	if entry == null or player == null:
		respawn_player()
		return
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


func _find_entry(entry_id: StringName) -> RoomEntry:
	for node in find_children("*", "RoomEntry", true, false):
		if (node as RoomEntry).id == entry_id:
			return node
	push_warning("Room: no existe la entrada '%s'; se usa el punto de aparición." % entry_id)
	return null


func respawn_player() -> void:
	if player == null or spawn_point == null:
		return
	player.teleport_to(spawn_point.global_position)
	_snap_camera()


func _on_player_died() -> void:
	var game_state := _game_state()
	if game_state:
		game_state.apply_death_penalty()
	await _scene_manager().transition(_respawn_at_checkpoint)


func _on_progress_changed() -> void:
	if player:
		player.apply_progress(_game_state())


func _respawn_at_checkpoint() -> void:
	var target := checkpoint if checkpoint else spawn_point
	if target:
		player.teleport_to(target.global_position)
	player.damage.revive()
	_snap_camera()


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
