class_name LifeFragment
extends Node2D
## Fragmento de vida: un pedazo roto (un cuarto) de un cristal de integridad. Flota y brilla; cuando
## Kai se acerca (o al llamar attract()) vuela hacia él y aparece la ventana para reclamarlo
## (LifeFragmentWindow). Con GameState.LIFE_FRAGMENTS_PER_MASK (4) se forma una vida nueva. Se recoge
## una sola vez (flag).
## Uso: LifeFragment.spawn(sala, posición, &"fragmento_vida_jefe_contrasena")

signal collected(completed_life: bool)

## Distancia a la que vuela hacia Kai solo, y a la que se recoge.
const MAGNET_RADIUS := 40.0
const PICKUP_RADIUS := 8.0

## Flag que queda al recogerlo (así no vuelve a aparecer).
var flag: StringName = &""

var _time := 0.0
var _attracted := false
var _collected := false
var _velocity := Vector2.ZERO


static func spawn(parent: Node, at: Vector2, flag_id: StringName) -> LifeFragment:
	var fragment := LifeFragment.new()
	fragment.flag = flag_id
	parent.add_child(fragment)
	fragment.global_position = at
	return fragment


func _ready() -> void:
	z_index = 6
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	RingBurst.spawn(get_parent(), global_position, MaskIcon.BRIGHT)


## Vuela hacia Kai aunque esté lejos (al terminar la pelea contra el jefe).
func attract() -> void:
	_attracted = true


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _collected:
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var target := player.global_position + Vector2(0, -18)
	var to := target - global_position
	if _time > 0.6 and to.length() < MAGNET_RADIUS:
		_attracted = true
	if not _attracted:
		return
	_velocity = _velocity.lerp(to.normalized() * (120.0 + _time * 40.0), 0.15)
	global_position += _velocity * delta
	if to.length() < PICKUP_RADIUS:
		_collect()


## Al tocarlo aparece la ventana «¡Has obtenido un fragmento de vida!»: reclamarlo lo suma.
func _collect() -> void:
	_collected = true
	visible = false
	PixelBurst.spawn(get_parent(), global_position, [MaskIcon.BRIGHT, MaskIcon.PALE, Color.WHITE], 14, 70.0)
	var game_state := get_node_or_null("/root/GameState")
	if game_state and flag != &"":
		game_state.set_flag(flag)
	var completed: bool = await LifeFragmentWindow.claim(self)
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if completed and player:
		player.health.restore_full()
	collected.emit(completed)
	queue_free()


func _draw() -> void:
	var bob := sin(_time * 2.5) * 2.0
	var c := Vector2(0, bob)
	# Brillo y destellos alrededor.
	for i in 4:
		draw_circle(c, 7.0 + i * 3.0, Color(MaskIcon.GLOW, 0.08))
	var twinkle := maxf(0.0, sin(_time * 4.0))
	draw_line(c + Vector2(-12, -6), c + Vector2(-12, -6 + 3.0 * twinkle), MaskIcon.PALE, 1.0)
	draw_line(c + Vector2(10, 7), c + Vector2(10 + 2.0 * twinkle, 7), MaskIcon.PALE, 1.0)
	# El pedazo: un cuarto del cristal (arriba a la derecha), con el borde roto del lado del centro.
	var s := 10.0
	var piece := PackedVector2Array([c + Vector2(-3, 4), c + Vector2(-3, -s), c + Vector2(s * 0.42 - 3, -s * 0.4),
		c + Vector2(s * 0.62 - 3, 4), c + Vector2(2, 2), c + Vector2(-1, 5)])
	draw_colored_polygon(piece, MaskIcon.DEEP)
	var middle := Vector2.ZERO
	for p in piece:
		middle += p
	middle /= piece.size()
	var inner := PackedVector2Array()
	for p in piece:
		inner.append(middle.lerp(p, 0.6))
	draw_colored_polygon(inner, MaskIcon.BRIGHT.lerp(MaskIcon.PALE, 0.3 + 0.2 * sin(_time * 3.0)))
	var edge := piece.duplicate()
	edge.append(edge[0])
	draw_polyline(edge, MaskIcon.PALE, 1.0, true)
	draw_circle(middle, 1.5, MaskIcon.CORE)
