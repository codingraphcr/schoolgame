class_name DeathSequence
extends Node2D
## Muerte y reaparición de Kai (hoja de Ariel "Animación de muerte y reaparición"), en magenta:
##   Muerte: 1. impacto (estallido) · 2. aturdimiento (pose de daño) · 3. cae de rodillas ·
##   4. se desploma · 5. queda en el suelo · 6-9. se desintegra en píxeles con líneas de glitch
##   hasta desaparecer · 10. pantalla "CONEXIÓN PERDIDA..." con glitch.
##   Reaparición (último punto de control): 11. punto de luz magenta · 12. se rearma desde los
##   píxeles · 13-14. aparece de rodillas y se levanta · 15. vuelve el control.
## Uso (lo hace la sala): await DeathSequence.play(jugador, sala._respawn_at_checkpoint)

const MAGENTA := Color("ff3dd8")
const PINK := Color("ff9cf2")
const DEEP := Color("7a1a9c")
const LIGHT := Color("ffe6fb")
const NIGHT := Color("0b0614")
## Duración de cada parte (segundos).
const STUN_TIME := 0.55
const KNEEL_TIME := 0.35
const FLOOR_TIME := 0.55
const DISSOLVE_TIME := 0.9
const LOST_TIME := 0.9
const BEACON_TIME := 0.45
const BUILD_TIME := 0.7
const RISE_TIME := 0.45

var player: Player
var _visual: Node
var _fragments: Array[Dictionary] = []
## Líneas de glitch horizontales mientras se desintegra (0 = no hay).
var _glitch := 0.0
## Punto de luz de la reaparición (0 = apagado, 1 = encendido).
var _beacon := 0.0
var _rays := 0.0
var _time := 0.0


static func play(target: Player, respawn: Callable) -> void:
	var sequence := DeathSequence.new()
	sequence.player = target
	target.get_parent().add_child(sequence)
	await sequence._run(respawn)
	sequence.queue_free()


func _ready() -> void:
	z_index = 6
	_visual = player.get_node_or_null("Visual/Body/Kai")


func _process(delta: float) -> void:
	_time += delta
	_rays = maxf(_rays - delta * 3.0, 0.0)
	for f in _fragments:
		f.vel += f.accel * delta
		f.pos += f.vel * delta
		f.life -= delta
	_fragments = _fragments.filter(func(f: Dictionary) -> bool: return f.life > 0.0)
	global_position = player.global_position
	queue_redraw()


func _run(respawn: Callable) -> void:
	player.controls_locked = true
	player.velocity = Vector2.ZERO
	# 1-2. Impacto y aturdimiento.
	_rays = 1.0
	_burst(18, Vector2(0, -16), 150.0)
	_pose(&"dano", STUN_TIME + 0.1)
	await _wait(STUN_TIME)
	# 3. Cae de rodillas.
	_pose(&"curar_suelo_inicio", KNEEL_TIME + 0.1)
	await _wait(KNEEL_TIME)
	# 4-5. Se desploma y queda en el suelo.
	_pose(&"muerte", 30.0)
	_shake(1.5, 0.15)
	_dust()
	await _wait(FLOOR_TIME)
	# 6-9. Se desintegra en píxeles magenta, con líneas de glitch.
	Sfx.play(&"death_dissolve")
	await _dissolve(0.0, 1.0, DISSOLVE_TIME, false)
	_glitch = 0.0
	await _wait(0.25)
	# 10. "CONEXIÓN PERDIDA..." y, a oscuras, pasa al último punto de control.
	Sfx.play(&"connection_lost")
	await _connection_lost(respawn)
	# 11. Punto de luz magenta en el punto de control.
	var tween := create_tween()
	tween.tween_property(self, "_beacon", 1.0, BEACON_TIME).set_trans(Tween.TRANS_SINE)
	await tween.finished
	# 12. Se rearma desde los píxeles (de rodillas).
	Sfx.play(&"respawn_build")
	_pose(&"curar_suelo_inicio", BUILD_TIME + RISE_TIME)
	await _dissolve(1.0, 0.0, BUILD_TIME, true)
	_burst(14, Vector2(0, -16), 70.0)
	# 13-14. Se levanta.
	var fade := create_tween()
	fade.tween_property(self, "_beacon", 0.0, RISE_TIME)
	await _wait(RISE_TIME)
	# 15. Vuelve el control (con la invulnerabilidad de siempre al reaparecer).
	player.damage.is_respawning = false
	player.controls_locked = false
	player.damage.invulnerable_timer = player.damage.invulnerability_time


## Disuelve o rearma a Kai en píxeles; los fragmentos salen del cuerpo (o llegan a él, si inward).
func _dissolve(from: float, to: float, seconds: float, inward: bool) -> void:
	var elapsed := 0.0
	var spawn := 0.0
	while elapsed < seconds:
		var delta := get_process_delta_time()
		elapsed += delta
		var k := clampf(elapsed / seconds, 0.0, 1.0)
		_set_dissolve(lerpf(from, to, k))
		_glitch = sin(k * PI) if not inward else 0.0
		spawn += delta * 70.0
		while spawn >= 1.0:
			spawn -= 1.0
			_fragment(inward)
		await get_tree().process_frame
	_set_dissolve(to)


## Pantalla oscura con glitch y el cartel "CONEXIÓN PERDIDA...". A mitad, a oscuras, la sala
## mueve a Kai al punto de control y le devuelve la vida (respawn); sigue sin control.
func _connection_lost(respawn: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 92
	add_child(layer)
	var screen := ConnectionLostScreen.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.modulate.a = 0.0
	layer.add_child(screen)
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, 0.2)
	await tween.finished
	await _wait(LOST_TIME * 0.5)
	_fragments.clear()
	respawn.call()
	player.damage.is_respawning = true
	player.controls_locked = true
	_set_dissolve(1.0)
	await _wait(LOST_TIME * 0.5)
	tween = create_tween()
	tween.tween_property(screen, "modulate:a", 0.0, 0.25)
	await tween.finished
	layer.queue_free()


func _draw() -> void:
	# Estallido del impacto: rayos magenta desde el pecho.
	if _rays > 0.0:
		for i in 10:
			var angle := TAU * i / 10.0 + 0.3
			var dir := Vector2(cos(angle), sin(angle))
			draw_line(Vector2(0, -16) + dir * 6.0, Vector2(0, -16) + dir * (14.0 + 26.0 * (1.0 - _rays)), Color(PINK, _rays), 1.5)
		draw_circle(Vector2(0, -16), 9.0 * _rays, Color(LIGHT, _rays * 0.8))
	# Glitch: franjas horizontales sobre el cuerpo mientras se desintegra.
	if _glitch > 0.0 and not GameSettings.reduce_glitch:
		for i in 4:
			if randf() < 0.6:
				var y := randf_range(-14.0, 0.0)
				draw_rect(Rect2(randf_range(-30.0, -8.0), y, randf_range(14.0, 40.0), 1.0), Color([MAGENTA, PINK].pick_random(), 0.7 * _glitch))
		# Brillo en el suelo bajo el cuerpo.
		draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.2))
		draw_circle(Vector2.ZERO, 26.0, Color(MAGENTA, 0.25 * _glitch))
		draw_set_transform(Vector2.ZERO)
	# Punto de luz de la reaparición: haz vertical, rombo y brillo en el suelo.
	if _beacon > 0.0:
		var pulse := 0.85 + 0.15 * sin(_time * 8.0)
		draw_rect(Rect2(-1.0, -70.0 * _beacon, 2.0, 70.0 * _beacon), Color(LIGHT, 0.7 * _beacon))
		draw_rect(Rect2(-4.0, -60.0 * _beacon, 8.0, 60.0 * _beacon), Color(MAGENTA, 0.25 * _beacon))
		var c := Vector2(0, -22)
		var s := 7.0 * _beacon * pulse
		var diamond := PackedVector2Array([c + Vector2(0, -s * 1.4), c + Vector2(s, 0), c + Vector2(0, s * 1.4), c + Vector2(-s, 0), c + Vector2(0, -s * 1.4)])
		draw_polyline(diamond, Color(PINK, _beacon), 1.5)
		draw_circle(c, 2.0 * _beacon, Color(LIGHT, _beacon))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, 22.0 * _beacon, Color(MAGENTA, 0.3 * _beacon))
		draw_circle(Vector2.ZERO, 10.0 * _beacon, Color(LIGHT, 0.35 * _beacon))
		draw_set_transform(Vector2.ZERO)
	for f in _fragments:
		var color: Color = f.color
		color.a *= clampf(f.life / 0.25, 0.0, 1.0)
		draw_rect(Rect2(f.pos.round(), f.size), color)


## Un píxel del cuerpo: sube flotando al desintegrarse, o llega desde afuera al rearmarse.
func _fragment(inward: bool) -> void:
	var body := Vector2(randf_range(-22.0, 22.0), randf_range(-12.0, 0.0))
	if inward:
		body = Vector2(randf_range(-10.0, 10.0), randf_range(-34.0, 0.0))
		var start := body + Vector2(randf_range(-30.0, 30.0), randf_range(-40.0, 10.0))
		_fragments.append({ "pos": start, "vel": (body - start) * 2.2, "accel": Vector2.ZERO, "life": 0.45,
			"size": Vector2([1, 2].pick_random(), [1, 2].pick_random()), "color": [MAGENTA, PINK, LIGHT].pick_random() })
		return
	_fragments.append({ "pos": body, "vel": Vector2(randf_range(-12.0, 12.0), randf_range(-40.0, -15.0)),
		"accel": Vector2(0, -20.0), "life": randf_range(0.5, 1.0),
		"size": Vector2([1, 2, 2, 3].pick_random(), [1, 2].pick_random()), "color": [MAGENTA, PINK, DEEP, LIGHT].pick_random() })


func _burst(count: int, at: Vector2, speed: float) -> void:
	for i in count:
		var angle := TAU * i / count
		_fragments.append({ "pos": at, "vel": Vector2(cos(angle), sin(angle)) * randf_range(0.5, 1.0) * speed,
			"accel": Vector2.ZERO, "life": randf_range(0.25, 0.5), "size": Vector2(2, 2), "color": [MAGENTA, PINK, LIGHT].pick_random() })


## Polvo al desplomarse.
func _dust() -> void:
	for i in 10:
		_fragments.append({ "pos": Vector2(randf_range(-20.0, 20.0), 0.0), "vel": Vector2(randf_range(-30.0, 30.0), randf_range(-25.0, -8.0)),
			"accel": Vector2(0, 40.0), "life": randf_range(0.3, 0.5), "size": Vector2(1, 1), "color": Color(PINK, 0.6) })


func _pose(anim: StringName, seconds: float) -> void:
	if _visual and _visual.has_method("play_pose"):
		_visual.play_pose(anim, seconds)


func _set_dissolve(amount: float) -> void:
	if _visual and _visual.has_method("set_dissolve"):
		_visual.set_dissolve(amount)


func _shake(strength: float, duration: float) -> void:
	var room := player.owner as Room
	if room and room.camera:
		room.camera.shake(strength, duration)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
