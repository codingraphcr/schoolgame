class_name EntityEye
extends Node2D
## El ojo de la entidad desconocida en la computadora del profesor (concepto de Ariel): un monitor
## rosa con un ojo que vigila a Kai. Acompaña a la cámara (queda en la parte de arriba de la
## pantalla, detrás del juego), mira hacia Kai y a veces hacia otros lados, parpadea, y tiene
## encima el panel "OBSERVANDO". Cuando Kai llega a la terminal, el ojo se cierra y desaparece.
## Después de resolver la terminal ya no vuelve a aparecer.

enum State { WATCHING, CLOSING, GONE }

const PINK := Color("ff3ea5")
const PINK_LIGHT := Color("ff9fd2")
const DEEP := Color("2a0b1f")
const PUPIL := Color("3a0820")
const QUEST := &"contrasena_profesor"
## Paso a partir del cual ya no está (la terminal ya se resolvió).
const GONE_FROM_STEP := &"cambiar_contrasena"

## La terminal: al acercarse Kai, el ojo se cierra.
@export var terminal: Node2D
@export var close_distance := 120.0
## Dónde queda respecto al centro de la pantalla.
@export var screen_offset := Vector2(0, -58)

var state := State.WATCHING
var openness := 1.0
var _time := 0.0
var _look := Vector2.ZERO
var _glance := Vector2.ZERO
var _glance_left := 0.0
var _next_glance := 3.0
var _next_blink := 2.5
var _blink := 0.0
var _fade := 1.0
## Transformación del dibujo de este cuadro (temblor y aplastado al cerrarse).
var _shake := Vector2.ZERO
var _collapse := 1.0
## Si ya se ubicó una vez junto a la cámara (en el primer cuadro la cámara aún no está lista).
var _placed := false


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state and game_state.has_reached_step(QUEST, GONE_FROM_STEP):
		state = State.GONE
		visible = false
	_follow_camera(true, 0.0)


func _process(delta: float) -> void:
	if state == State.GONE:
		return
	_time += delta
	_follow_camera(not _placed, delta)
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if state == State.WATCHING:
		if terminal and player and player.global_position.distance_to(terminal.global_position) < close_distance:
			close()
		_update_gaze(delta, player)
		_update_blink(delta)
	elif state == State.CLOSING:
		openness = move_toward(openness, 0.0, delta * 3.0)
		if openness <= 0.0:
			_fade = move_toward(_fade, 0.0, delta * 2.2)
			if _fade <= 0.0:
				state = State.GONE
				visible = false
	queue_redraw()


## Se cierra y desaparece (al llegar a la terminal).
func close() -> void:
	if state == State.WATCHING:
		state = State.CLOSING


func _follow_camera(instant: bool, delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var target := camera.get_screen_center_position() + screen_offset
	global_position = target if instant else global_position.lerp(target, 1.0 - exp(-delta * 6.0))
	_placed = _placed or (instant and delta > 0.0)


## Mira hacia Kai; cada tanto echa un vistazo hacia otro lado.
func _update_gaze(delta: float, player: Node2D) -> void:
	_next_glance -= delta
	if _next_glance <= 0.0:
		_glance = Vector2(randf_range(-1.0, 1.0), randf_range(-0.6, 0.6)).normalized()
		_glance_left = randf_range(0.6, 1.2)
		_next_glance = randf_range(3.0, 6.0)
	var wanted := Vector2.ZERO
	if _glance_left > 0.0:
		_glance_left -= delta
		wanted = _glance
	elif player:
		wanted = (player.global_position + Vector2(0, -14) - global_position).normalized()
	_look = _look.lerp(wanted, 1.0 - exp(-delta * 6.0))


func _update_blink(delta: float) -> void:
	_next_blink -= delta
	if _next_blink <= 0.0 and _blink <= 0.0:
		_blink = 0.28
		_next_blink = randf_range(2.5, 5.5)
	if _blink > 0.0:
		_blink -= delta
		var k := 1.0 - absf(_blink / 0.28 * 2.0 - 1.0)
		openness = 1.0 - k
	else:
		openness = move_toward(openness, 1.0, delta * 6.0)


func _draw() -> void:
	var collapse := clampf(_fade, 0.0, 1.0)
	var alpha := collapse
	var glitchy := state == State.CLOSING and not GameSettings.reduce_glitch and randf() < 0.3
	_shake = Vector2(randf_range(-3, 3), 0) if glitchy else Vector2.ZERO
	_collapse = collapse
	draw_set_transform(_shake, 0.0, Vector2(1.0, _collapse))
	var frame := Rect2(-120, -46, 240, 92)
	# Panel "OBSERVANDO".
	var panel := Rect2(-86, -84, 172, 26)
	draw_rect(panel, Color(1, 1, 1, 0.55 * alpha))
	draw_rect(panel, Color(PINK, 0.5 * alpha), false, 1.0)
	_text(panel.position + Vector2(8, 12), "OBSERVANDO", Color(PINK, 0.9 * alpha))
	var bar := Rect2(panel.position + Vector2(8, 17), Vector2(110, 4))
	draw_rect(bar, Color(PINK, 0.15 * alpha))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * (0.2 + 0.15 * sin(_time * 1.3)), bar.size.y)), Color(PINK, 0.7 * alpha))
	# Resplandor y marco.
	for i in 4:
		draw_rect(frame.grow(4 + i * 5), Color(PINK, 0.08 * alpha / (i + 1)), false, 5.0)
	draw_rect(frame, Color(DEEP, 0.92 * alpha))
	for y in range(int(frame.position.y) + 2, int(frame.end.y), 3):
		draw_line(Vector2(frame.position.x, y), Vector2(frame.end.x, y), Color(PINK, 0.06 * alpha), 1.0)
	draw_rect(frame, Color(PINK, 0.9 * alpha), false, 2.0)
	for corner in [frame.position, Vector2(frame.end.x, frame.position.y), frame.end, Vector2(frame.position.x, frame.end.y)]:
		var dx: float = 1.0 if corner.x < 0.0 else -1.0
		var dy: float = 1.0 if corner.y < 0.0 else -1.0
		var outside: Vector2 = corner - Vector2(dx, dy) * 8.0
		draw_line(outside, outside + Vector2(dx * 22.0, 0), Color(PINK_LIGHT, alpha), 2.0)
		draw_line(outside, outside + Vector2(0, dy * 22.0), Color(PINK_LIGHT, alpha), 2.0)
	# Hilos que gotean del monitor.
	for i in 9:
		var x := -100.0 + i * 25.0 + sin(i * 3.1) * 6.0
		var length := 10.0 + 14.0 * absf(sin(_time * 0.8 + i * 1.7))
		draw_line(Vector2(x, frame.end.y + 3), Vector2(x, frame.end.y + 3 + length), Color(PINK, 0.45 * alpha), 1.0)
		draw_line(Vector2(x + 7, frame.position.y - 3), Vector2(x + 7, frame.position.y - 3 - length * 0.6), Color(PINK, 0.3 * alpha), 1.0)
	_draw_eye(alpha)
	draw_set_transform(Vector2.ZERO)


func _draw_eye(alpha: float) -> void:
	var half_w := 82.0
	var half_h := 30.0 * openness
	if half_h < 1.0:
		draw_line(Vector2(-half_w, 0), Vector2(half_w, 0), Color(PINK, alpha), 2.0)
		return
	var almond := PackedVector2Array()
	for i in 25:
		var x := lerpf(-half_w, half_w, i / 24.0)
		almond.append(Vector2(x, -half_h * pow(1.0 - pow(x / half_w, 2.0), 0.75)))
	for i in range(24, -1, -1):
		var x := lerpf(-half_w, half_w, i / 24.0)
		almond.append(Vector2(x, half_h * pow(1.0 - pow(x / half_w, 2.0), 0.75)))
	# Contorno doble del ojo.
	var outer := almond.duplicate()
	for i in outer.size():
		outer[i] *= 1.12
	outer.append(outer[0])
	draw_polyline(outer, Color(PINK, 0.45 * alpha), 1.5, true)
	draw_colored_polygon(almond, Color("120410", alpha))
	# Iris y pupila, recortados por los párpados.
	var center := Vector2(_look.x * 34.0, _look.y * 8.0)
	_clipped(_circle(center, 26.0), almond, Color(PINK, alpha))
	_clipped(_circle(center, 19.0), almond, Color(PINK_LIGHT, alpha))
	_clipped(_circle(center, 13.0), almond, Color(PINK, alpha))
	var pupil := PackedVector2Array([center + Vector2(-5, -18), center + Vector2(5, -18), center + Vector2(5, 18), center + Vector2(-5, 18)])
	_clipped(pupil, almond, Color(PUPIL, alpha))
	_clipped(PackedVector2Array([center + Vector2(-11, -11), center + Vector2(-7, -11), center + Vector2(-7, -7), center + Vector2(-11, -7)]), almond, Color(1, 1, 1, 0.9 * alpha))
	almond.append(almond[0])
	draw_polyline(almond, Color(PINK, alpha), 2.0, true)


func _clipped(shape: PackedVector2Array, clip: PackedVector2Array, color: Color) -> void:
	for piece in Geometry2D.intersect_polygons(shape, clip):
		draw_colored_polygon(piece, color)


func _circle(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * i / 20.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _text(pos: Vector2, text: String, color: Color) -> void:
	draw_set_transform(_shake + pos * Vector2(1.0, _collapse), 0.0, Vector2(0.5, 0.5 * _collapse))
	draw_string(ThemeDB.fallback_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	draw_set_transform(_shake, 0.0, Vector2(1.0, _collapse))
