extends Node2D
## Kai en estilo vectorial con animación por huesos (cutout).
## Cada pieza (muslo, pierna, brazo, cabeza...) gira alrededor de su articulación y las poses
## se mezclan suavemente. En el juego final esto se haría con Skeleton2D + Bone2D y un
## AnimationPlayer con fotogramas clave; aquí las poses se calculan por código para la muestra.

const SKIN := Color("f0c39a")
const SKIN_D := Color("c98d6b")
const HAIR := Color("2a2233")
const HAIR_L := Color("4a3d58")
const HOOD := Color("e0913a")
const HOOD_D := Color("a85d24")
const HOOD_L := Color("ffc070")
const PANTS := Color("2c3555")
const SHOE := Color("16161f")
const CYAN := Color("3ef2ff")
const CYAN_M := Color("1fa5c4")
const MET := Color("5a6788")
const OUTLINE := Color(0.03, 0.04, 0.09)

const THIGH := 6.5
const SHIN := 6.0
const UPPER_ARM := 5.0
const FOREARM := 4.5
const SCARF_POINTS := 8
const SCARF_SEGMENT := 2.6

var player: Player

## Ángulos actuales de las articulaciones (radianes; positivo = hacia adelante).
## @export_storage: se copian al duplicar el nodo, así las estelas del dash conservan la pose.
@export_storage var _pose := {
	"thigh_f": 0.0, "shin_f": 0.0, "thigh_b": 0.0, "shin_b": 0.0,
	"arm_f": 0.0, "fore_f": 0.0, "arm_b": 0.0, "fore_b": 0.0,
	"lean": 0.0, "bob": 0.0, "head": 0.0,
}
var _phase := 0.0
var _time := 0.0
@export_storage var _blink := 3.0
@export_storage var _scarf := PackedVector2Array()


func _ready() -> void:
	if _scarf.is_empty():
		_scarf.resize(SCARF_POINTS)
		_scarf.fill(to_global(Vector2(-2, -22)))


func _process(delta: float) -> void:
	if player == null:
		return
	_time += delta
	_blink -= delta
	if _blink < -0.12:
		_blink = randf_range(2.5, 4.5)
	var target := _target_pose(delta)
	var blend := 1.0 - exp(-14.0 * delta)
	for key: String in _pose:
		_pose[key] = lerpf(_pose[key], target[key], blend)
	_update_scarf(delta)
	queue_redraw()


func _target_pose(delta: float) -> Dictionary:
	var speed := clampf(absf(player.velocity.x) / player.max_speed, 0.0, 1.0)
	match player.state:
		Player.State.RUN:
			_phase += delta * lerpf(6.0, 13.0, speed)
			var s := sin(_phase)
			return {
				"thigh_f": s * 0.8, "shin_f": -maxf(0.0, -cos(_phase)) * 1.1 - 0.15,
				"thigh_b": -s * 0.8, "shin_b": -maxf(0.0, cos(_phase)) * 1.1 - 0.15,
				"arm_f": -s * 0.7, "fore_f": 0.9, "arm_b": s * 0.7, "fore_b": 0.9,
				"lean": 0.14 * speed, "bob": absf(cos(_phase)) * 1.2, "head": -0.05,
			}
		Player.State.JUMP:
			return {
				"thigh_f": 0.9, "shin_f": -1.3, "thigh_b": -0.2, "shin_b": -0.5,
				"arm_f": 2.3, "fore_f": 0.4, "arm_b": 1.9, "fore_b": 0.3,
				"lean": 0.05, "bob": 0.0, "head": -0.12,
			}
		Player.State.FALL:
			return {
				"thigh_f": 0.35, "shin_f": -0.4, "thigh_b": -0.25, "shin_b": -0.2,
				"arm_f": 1.4, "fore_f": -0.3, "arm_b": 1.2, "fore_b": -0.3,
				"lean": 0.0, "bob": 0.0, "head": 0.08,
			}
		Player.State.DASH:
			return {
				"thigh_f": 0.7, "shin_f": -0.9, "thigh_b": -0.9, "shin_b": -0.4,
				"arm_f": -1.1, "fore_f": 0.3, "arm_b": -1.3, "fore_b": 0.2,
				"lean": 0.45, "bob": 1.5, "head": -0.1,
			}
		Player.State.WALL_SLIDE:
			# Espalda contra la pared (detrás) y una mano apoyada en ella.
			return {
				"thigh_f": 0.5, "shin_f": -0.8, "thigh_b": 0.2, "shin_b": -0.6,
				"arm_f": 0.3, "fore_f": 0.5, "arm_b": -2.4, "fore_b": 0.2,
				"lean": -0.12, "bob": 0.5, "head": 0.1,
			}
	# IDLE: respiración suave.
	var breath := sin(_time * 2.2)
	return {
		"thigh_f": 0.08, "shin_f": 0.0, "thigh_b": -0.08, "shin_b": 0.0,
		"arm_f": 0.12 + breath * 0.04, "fore_f": 0.25, "arm_b": -0.08, "fore_b": 0.2,
		"lean": 0.0, "bob": (breath + 1.0) * 0.35, "head": breath * 0.03,
	}


func _update_scarf(delta: float) -> void:
	var facing := signf(global_transform.x.x)
	var speed := clampf(absf(player.velocity.x) / player.max_speed, 0.0, 1.0)
	_scarf[0] = to_global(_neck() + Vector2(-2.0, 1.0))
	var hang := Vector2(-facing * SCARF_SEGMENT * (0.3 + 0.7 * speed), SCARF_SEGMENT * (0.85 - 0.7 * speed))
	if player.velocity.y > 60.0:
		hang.y -= SCARF_SEGMENT * 1.3
	for i in range(1, SCARF_POINTS):
		var wave := Vector2(0.0, sin(_time * 8.0 - i * 0.8) * 0.5 * (0.3 + speed))
		var target := _scarf[i - 1] + hang + wave
		var point := _scarf[i].lerp(target, 1.0 - exp(-20.0 * delta))
		var offset := point - _scarf[i - 1]
		if offset.length() > SCARF_SEGMENT:
			point = _scarf[i - 1] + offset.normalized() * SCARF_SEGMENT
		_scarf[i] = point


func _hip() -> Vector2:
	return Vector2(0.0, -12.5 + _pose.bob)


func _neck() -> Vector2:
	return _hip() + Vector2(0.0, -10.5).rotated(_pose.lean)


# --- Dibujo ---

func _draw() -> void:
	var hip := _hip()
	var neck := _neck()
	var shoulder := neck + Vector2(0.5, 2.0).rotated(_pose.lean)

	_draw_scarf_tail()
	_limb(shoulder + Vector2(-1.5, 0), _pose.arm_b, _pose.fore_b, UPPER_ARM, FOREARM, 2.6, HOOD_D, SKIN_D)
	_leg(hip + Vector2(-1.0, 0), _pose.thigh_b, _pose.shin_b, PANTS.darkened(0.3))
	_leg(hip + Vector2(1.0, 0), _pose.thigh_f, _pose.shin_f, PANTS)
	_draw_torso(hip, neck)
	_draw_head(neck)
	_limb(shoulder, _pose.arm_f, _pose.fore_f, UPPER_ARM, FOREARM, 2.8, HOOD, SKIN)


## Dibuja una extremidad de dos huesos. Devuelve la posición del extremo.
func _limb(origin: Vector2, upper_angle: float, lower_angle: float, upper_len: float, lower_len: float,
		width: float, color: Color, end_color: Color) -> Vector2:
	var elbow := origin + Vector2(0.0, upper_len).rotated(-upper_angle)
	var hand := elbow + Vector2(0.0, lower_len).rotated(-(upper_angle + lower_angle))
	_capsule(origin, elbow, width, color)
	_capsule(elbow, hand, width * 0.9, color)
	draw_circle(hand, width * 0.62, OUTLINE)
	draw_circle(hand, width * 0.48, end_color)
	return hand


func _leg(origin: Vector2, thigh: float, shin: float, color: Color) -> void:
	var knee := origin + Vector2(0.0, THIGH).rotated(-thigh)
	var foot := knee + Vector2(0.0, SHIN).rotated(-(thigh + shin))
	_capsule(origin, knee, 3.4, color)
	_capsule(knee, foot, 3.0, color)
	var shoe := VectorCanvas.rounded_rect(Rect2(foot + Vector2(-1.8, -1.2), Vector2(5.0, 2.6)), 1.2)
	draw_colored_polygon(shoe, SHOE)


func _capsule(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	draw_line(a, b, OUTLINE, width + 1.4, true)
	draw_circle(a, (width + 1.4) * 0.5, OUTLINE)
	draw_circle(b, (width + 1.4) * 0.5, OUTLINE)
	draw_line(a, b, color, width, true)
	draw_circle(a, width * 0.5, color)
	draw_circle(b, width * 0.5, color)


func _draw_torso(hip: Vector2, neck: Vector2) -> void:
	var up := (neck - hip).normalized()
	var side := Vector2(-up.y, up.x)
	var body := PackedVector2Array([
		hip + side * 5.2 + up * 0.5,
		hip - side * 5.0 + up * 0.5,
		neck - side * 4.0,
		neck + side * 3.6,
	])
	var colors := PackedColorArray([HOOD, HOOD_D, HOOD_D, HOOD_L])
	# Capucha recogida detrás del cuello.
	draw_circle(neck - side * 3.0 + up * -0.5, 3.0, OUTLINE)
	draw_circle(neck - side * 3.0 + up * -0.5, 2.3, HOOD_D)
	draw_polygon(body, colors)
	var closed := body.duplicate()
	closed.append(body[0])
	draw_polyline(closed, OUTLINE, 0.9, true)
	# Bolsillo y cordones.
	draw_line(hip - side * 2.5 + up * 3.5, hip + side * 1.5 + up * 3.5, HOOD_D, 0.8, true)
	draw_line(neck - side * 1.0 + up * -1.0, neck - side * 1.3 + up * -4.0, HOOD_L, 0.6, true)


func _draw_head(neck: Vector2) -> void:
	draw_set_transform(neck, _pose.lean * 0.5 + _pose.head)
	var c := Vector2(1.0, -6.5)
	# Pelo (parte trasera) y cara.
	draw_circle(c + Vector2(-1.2, -0.8), 6.8, OUTLINE)
	draw_circle(c + Vector2(-1.2, -0.8), 6.0, HAIR)
	draw_circle(c + Vector2(0.8, 0.6), 5.4, OUTLINE)
	draw_circle(c + Vector2(0.8, 0.6), 4.7, SKIN)
	draw_circle(c + Vector2(1.6, 3.2), 2.2, SKIN_D.lerp(SKIN, 0.6))
	# Flequillo.
	var fringe := PackedVector2Array([
		c + Vector2(-5.5, -2.5), c + Vector2(-2.0, -6.8), c + Vector2(4.0, -5.8),
		c + Vector2(6.2, -2.2), c + Vector2(3.4, -2.6), c + Vector2(1.0, -1.2), c + Vector2(-1.5, -2.8),
	])
	draw_colored_polygon(fringe, HAIR)
	draw_line(c + Vector2(-2.5, -5.2), c + Vector2(1.5, -5.6), HAIR_L, 0.8, true)
	# Ojo grande y expresivo.
	if _blink > 0.0:
		draw_circle(c + Vector2(3.1, 0.4), 1.25, OUTLINE)
		draw_circle(c + Vector2(3.5, -0.1), 0.45, Color.WHITE)
	else:
		draw_line(c + Vector2(2.0, 0.6), c + Vector2(4.2, 0.6), OUTLINE, 0.6, true)
	# Auriculares con micrófono.
	draw_arc(c + Vector2(-1.0, -0.5), 6.3, PI * 1.05, PI * 1.75, 12, CYAN_M, 1.0, true)
	draw_circle(c + Vector2(-3.4, 0.8), 2.3, OUTLINE)
	draw_circle(c + Vector2(-3.4, 0.8), 1.7, MET)
	draw_line(c + Vector2(-2.6, 2.5), c + Vector2(3.0, 4.2), MET, 0.6, true)
	draw_circle(c + Vector2(3.2, 4.2), 0.8, CYAN)
	draw_set_transform(Vector2.ZERO)


func _draw_scarf_tail() -> void:
	var count := _scarf.size()
	for i in count - 1:
		var a := to_local(_scarf[i])
		var b := to_local(_scarf[i + 1])
		var width := lerpf(2.8, 0.9, float(i) / (count - 1))
		draw_line(a, b, OUTLINE, width + 1.2, true)
		draw_line(a, b, CYAN_M, width, true)
		draw_line(a, b, CYAN, width * 0.35, true)
	var neck := _neck()
	draw_line(neck + Vector2(-3.0, 1.2), neck + Vector2(3.5, 1.4), OUTLINE, 3.4, true)
	draw_line(neck + Vector2(-3.0, 1.2), neck + Vector2(3.5, 1.4), CYAN_M, 2.4, true)
