class_name GameCamera
extends Camera2D
## Cámara del juego: sigue a un objetivo con suavizado, mira hacia donde avanza el jugador,
## se adelanta hacia abajo en las caídas rápidas y solo se mueve verticalmente cuando
## el objetivo sale de un margen (no tiembla con cada salto).

@export var target: Node2D
## Distancia (px) que la cámara se adelanta en la dirección en la que mira el objetivo.
@export var look_ahead_distance := 40.0
@export var look_ahead_speed := 3.0
## Desplazamiento vertical para mostrar más espacio sobre el jugador.
@export var vertical_offset := -24.0
## Distancia (px) que la cámara se adelanta hacia abajo cuando el objetivo cae rápido.
@export var fall_look_ahead_distance := 56.0
## Velocidad de caída (px/s) a partir de la cual la cámara se adelanta hacia abajo.
@export var fall_look_ahead_threshold := 220.0
@export var fall_look_ahead_speed := 5.0

var _look_ahead := 0.0
var _fall_offset := 0.0


func _ready() -> void:
	snap_to_target()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var desired := 0.0
	if "facing" in target:
		desired = target.facing * look_ahead_distance
	_look_ahead = lerpf(_look_ahead, desired, 1.0 - exp(-look_ahead_speed * delta))

	var desired_fall := 0.0
	if "velocity" in target and target.velocity.y > fall_look_ahead_threshold:
		desired_fall = fall_look_ahead_distance
	_fall_offset = lerpf(_fall_offset, desired_fall, 1.0 - exp(-fall_look_ahead_speed * delta))

	global_position = target.global_position + Vector2(_look_ahead, vertical_offset + _fall_offset)


## Coloca la cámara sobre el objetivo sin transición (al cargar una sala o reaparecer).
func snap_to_target() -> void:
	if target == null:
		return
	_look_ahead = 0.0
	_fall_offset = 0.0
	global_position = target.global_position + Vector2(0.0, vertical_offset)
	reset_smoothing()


func set_limits(bounds: Rect2) -> void:
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
