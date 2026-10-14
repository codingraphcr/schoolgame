class_name ControlZone
extends Node2D
## Zona de control de Chip: un campo azul en el piso que ralentiza a Kai mientras está adentro (no hace
## daño: lo deja expuesto a los ataques de Glitch). Primero parpadea el borde (aviso), después se
## activa unos segundos y se apaga. El origen es el centro del piso de la zona.

var width := 130.0
var height := 60.0
var warning := 0.6
var duration := 3.2
## Velocidad de Kai adentro (1 = normal).
var slow := 0.45
var _time := 0.0
var _slowed: Player


func _ready() -> void:
	add_to_group(&"boss_attack")
	z_index = -1


func is_active() -> bool:
	return _time >= warning and _time < warning + duration


func contains(point: Vector2) -> bool:
	var local := point - global_position
	return absf(local.x) <= width / 2.0 and local.y <= 4.0 and local.y >= -height


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	var kai := get_tree().get_first_node_in_group(&"player") as Player
	var inside := kai != null and is_active() and contains(kai.global_position)
	if inside and _slowed == null:
		_slowed = kai
		kai.speed_scale = slow
	elif not inside and _slowed != null:
		_release()
	if _time >= warning + duration:
		queue_free()


func _exit_tree() -> void:
	_release()


func _release() -> void:
	if is_instance_valid(_slowed):
		_slowed.speed_scale = 1.0
	_slowed = null


func _draw() -> void:
	var rect := Rect2(-width / 2.0, -height, width, height)
	if _time < warning:
		var blink := int(_time / 0.08) % 2 == 0
		draw_rect(rect, Color(SiblingArt.CHIP, 0.9 if blink else 0.35), false, 1.0)
		draw_line(Vector2(-width / 2.0, 0), Vector2(width / 2.0, 0), Color(SiblingArt.CHIP_LIGHT, 0.8), 2.0)
		return
	var fade := clampf((warning + duration - _time) / 0.3, 0.0, 1.0)
	draw_rect(rect, Color(SiblingArt.CHIP, 0.14 * fade))
	# Anillos que se aplanan sobre el piso, como en la hoja de Ariel.
	for k in 3:
		var t := fposmod(_time * 0.6 + k / 3.0, 1.0)
		var r := width / 2.0 * t
		draw_arc(Vector2.ZERO, r, PI, TAU, 24, Color(SiblingArt.CHIP_LIGHT, (1.0 - t) * 0.6 * fade), 1.0)
	draw_line(Vector2(-width / 2.0, 0), Vector2(width / 2.0, 0), Color(SiblingArt.CHIP_LIGHT, 0.9 * fade), 2.0)
	for x in range(int(-width / 2.0), int(width / 2.0), 12):
		var y := -fposmod(_time * 30.0 + x * 1.7, height)
		draw_rect(Rect2(x, y, 1, 3), Color(SiblingArt.CHIP_LIGHT, 0.5 * fade))
