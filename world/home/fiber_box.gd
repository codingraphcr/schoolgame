@tool
extends Node2D
## La caja de distribución de fibra óptica del poste de la calle de Kai (mundo físico): de ella salen los
## cables a las casas de la cuadra. Mientras la conexión está cortada (misión «Sin señal en el barrio»), la
## luz de estado parpadea en rojo y, con la Visión Digital, se ven los datos que no pasan (el acceso de
## Inmersión es un ImmersionPortal hijo). Restaurada (restored_flag), la luz queda verde y por los cables
## corre la señal hasta las casas. El origen es la base de la caja, sobre el poste.

@export var restored_flag: StringName = &"bosque_fibra_enlace_restaurado"
@export var failing_quest: StringName = &"senal_del_barrio"
## Hasta dónde llegan los cables (x relativas a la caja, a la altura de los techos).
@export var drops: PackedFloat32Array = [-160.0, 120.0, 260.0]

var _clock := 0.0


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func is_restored() -> bool:
	var state := get_node_or_null("/root/GameState")
	return state != null and state.has_flag(restored_flag) if not Engine.is_editor_hint() else true


func is_failing() -> bool:
	var state := get_node_or_null("/root/GameState")
	return not Engine.is_editor_hint() and state != null and state.has_reached_step(failing_quest) and not is_restored()


func _draw() -> void:
	var restored := is_restored()
	var failing := is_failing()
	# Cables a las casas (con la señal corriendo si está restaurada).
	for x in drops:
		var points := VectorCanvas.sag_curve(Vector2(0, -6), Vector2(x, 10), 8.0, 12)
		draw_polyline(points, Color("2a2a30"), 1.5)
		if restored:
			var t := fmod(_clock * 0.6 + absf(x) * 0.003, 1.0)
			draw_circle(points[int(t * (points.size() - 1))], 1.8, Color("9ff8ff"))
	# La caja.
	draw_rect(Rect2(-12, -22, 24, 26), Color("3a4a5a"))
	draw_rect(Rect2(-12, -22, 24, 26), Color("1a2430"), false, 1.0)
	draw_rect(Rect2(-9, -18, 18, 3), Color("5a6a7a"))
	var led := Color("4aff8a")
	if failing:
		led = Color("ff4a6a") if fmod(_clock, 0.8) < 0.4 else Color("4a1a24")
	elif not restored:
		led = Color("8a8a50")
	draw_circle(Vector2(7, -8), 2.2, led)
	if failing and fmod(_clock * 2.0, 3.0) < 0.2:
		draw_line(Vector2(-4, 4), Vector2(2, 12), Color("ffd84a"), 1.5)  # Chispa
