class_name Room
extends Node2D
## Sala del mundo. Calcula los límites de la cámara a partir del TileMapLayer y coloca al jugador
## en el punto de aparición. Si el jugador cae fuera, cuenta como peligro (1 máscara y vuelta al
## último suelo seguro). Si muere, reaparece en el punto de control con las máscaras llenas.
## El nodo raíz de cada sala usa filtro Nearest para que el pixel art se vea nítido.

@export var tile_layer: TileMapLayer
@export var player: Player
@export var camera: GameCamera
@export var spawn_point: Marker2D
## Dónde reaparece el jugador al morir (banco). Si está vacío, se usa spawn_point.
@export var checkpoint: Marker2D
## Distancia (px) bajo el borde inferior de la sala a partir de la cual el jugador reaparece.
@export var fall_limit_margin := 64.0

var bounds: Rect2


func _ready() -> void:
	bounds = _compute_bounds()
	if camera:
		camera.set_limits(bounds)
	if player:
		player.damage.died.connect(_on_player_died)
		player.damage.hurt.connect(_on_player_hurt)
		player.damage.hazard_respawned.connect(_snap_camera)
	respawn_player()


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y > bounds.end.y + fall_limit_margin:
		player.damage.fall_out_of_bounds()


func respawn_player() -> void:
	if player == null or spawn_point == null:
		return
	player.teleport_to(spawn_point.global_position)
	_snap_camera()


func _on_player_died() -> void:
	await _scene_manager().transition(_respawn_at_checkpoint)


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
	if tile_layer == null or tile_layer.tile_set == null:
		push_warning("Room: falta el TileMapLayer; la cámara no tendrá límites.")
		return Rect2(-100000, -100000, 200000, 200000)
	var used := tile_layer.get_used_rect()
	var tile_size := Vector2(tile_layer.tile_set.tile_size)
	var top_left := tile_layer.to_global(tile_layer.map_to_local(used.position) - tile_size / 2.0)
	return Rect2(top_left, Vector2(used.size) * tile_size)


## El autoload se obtiene por ruta (no por nombre global) para que este script también compile
## en las pruebas de línea de comandos, donde los autoloads se registran después.
func _scene_manager() -> Node:
	return get_node("/root/SceneManager")
