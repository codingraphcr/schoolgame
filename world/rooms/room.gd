class_name Room
extends Node2D
## Sala del mundo. Calcula los límites de la cámara a partir del TileMapLayer,
## coloca al jugador en el punto de aparición y lo devuelve ahí si cae fuera de la sala.
## El nodo raíz de cada sala usa filtro Nearest para que el pixel art se vea nítido.

@export var tile_layer: TileMapLayer
@export var player: Player
@export var camera: GameCamera
@export var spawn_point: Marker2D
## Distancia (px) bajo el borde inferior de la sala a partir de la cual el jugador reaparece.
@export var fall_limit_margin := 64.0

var bounds: Rect2


func _ready() -> void:
	bounds = _compute_bounds()
	if camera:
		camera.set_limits(bounds)
	respawn_player()


func _physics_process(_delta: float) -> void:
	if player and player.global_position.y > bounds.end.y + fall_limit_margin:
		respawn_player()


func respawn_player() -> void:
	if player == null or spawn_point == null:
		return
	player.teleport_to(spawn_point.global_position)
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
