class_name NullbladeReveal
extends Node2D
## La Nullblade se materializa por primera vez (secuencia de la hoja de Ariel):
##   1. Activación: Kai se agacha y un pulso de datos empieza a emerger.
##   2. Manifestación: fragmentos de código se expanden alrededor de un punto frente a Kai.
##   3. Condensación: los fragmentos se juntan en una línea y la espada se define en el aire.
##   4. Materialización: la espada se estabiliza con un destello.
##   5. Empuñadura: Kai la toma y los fragmentos se integran a su mano.
##   6. Lista: queda lista para el combate.
## Después muestra la tarjeta "NUEVO EQUIPAMIENTO DESBLOQUEADO".
## Uso: await NullbladeReveal.play(jugador)

signal done

const SWORD := preload("res://assets/art/items/nullblade/nullblade_espada.png")
const ART := preload("res://assets/art/items/nullblade/nullblade_arte.png")
const VIOLET := Color("8a5cff")
const LIGHT := Color("d9ccff")
const DEEP := Color("4b2bd6")
## Fin de cada fase (segundos desde el inicio).
const ACTIVATION := 0.6
const MANIFEST := 1.5
const CONDENSE := 2.2
const MATERIALIZE := 2.8
const GRIP := 3.4
const READY := 3.8

var player: Player
var _time := 0.0
var _fragments: Array[Dictionary] = []
var _sword: Sprite2D
var _light: PointLight2D
var _flash := 0.0
var _grip_target := Vector2.ZERO
var _phase := 0


## Reproduce la animación y la tarjeta; termina cuando el jugador cierra la tarjeta.
static func play(target: Player, show_card := true) -> void:
	var reveal := NullbladeReveal.new()
	reveal.player = target
	target.get_parent().add_child(reveal)
	reveal.global_position = target.global_position + Vector2(20 * target.facing, -24)
	await reveal.done
	reveal.queue_free()
	if show_card:
		await EquipmentCard.show_card(target, {
			"art": ART,
			"subtitle": "NUEVO EQUIPAMIENTO DESBLOQUEADO",
			"title": "NULLBLADE",
			"description": "Una hoja forjada a partir de código fragmentado,\ncapaz de cortar las amenazas que corrompen el sistema.",
			"banner": "¡NULLBLADE OBTENIDA!",
			"action": &"attack",
			"hint": "Pulsa %s para atacar" % GameSettings.key_name(&"attack"),
		})


func _ready() -> void:
	z_index = 6
	_sword = Sprite2D.new()
	_sword.texture = SWORD
	_sword.scale = Vector2(0.5, 0.0)
	_sword.modulate.a = 0.0
	_sword.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sword)
	_light = PointLight2D.new()
	_light.texture = load("res://assets/art/light_soft.tres")
	_light.color = VIOLET
	_light.energy = 0.0
	_light.texture_scale = 1.4
	add_child(_light)
	_kai_pose(&"curar_suelo_inicio", ACTIVATION + 1.6)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 2.5, 0.0)
	var reduced := GameSettings.reduce_glitch
	if _time < MANIFEST:
		# 1-2: pulso de datos y fragmentos que se expanden.
		var rate := 3 if _time < ACTIVATION else 9
		for i in rate:
			_spawn_fragment(randf_range(10.0, 46.0) if _time >= ACTIVATION else randf_range(4.0, 14.0))
		_light.energy = lerpf(0.0, 0.9, _time / MANIFEST)
	elif _time < CONDENSE:
		# 3: la espada se define (crece de una línea y parpadea).
		var t := (_time - MANIFEST) / (CONDENSE - MANIFEST)
		_sword.scale = Vector2(lerpf(0.12, 0.5, t), lerpf(0.2, 0.5, t))
		_sword.modulate.a = (0.35 + 0.65 * t) * (randf_range(0.5, 1.0) if not reduced else 1.0)
		_light.energy = 0.9 + t * 0.6
	elif _time < MATERIALIZE:
		# 4: estable, con destello y anillo.
		if _phase < 4:
			_phase = 4
			_flash = 1.0
			_burst(28)
			_shake()
		_sword.scale = Vector2(0.5, 0.5)
		_sword.modulate = Color(1, 1, 1, 1).lerp(Color(2, 2, 2, 1), _flash)
		_sword.position.y = sin(_time * 6.0) * 1.5
	elif _time < GRIP:
		# 5: Kai la toma; la espada va a su mano y se integra en fragmentos.
		if _phase < 5:
			_phase = 5
			_kai_pose(&"ataque_1", GRIP - MATERIALIZE + 0.2)
			_grip_target = to_local(player.global_position + Vector2(12 * player.facing, -14))
		var t := (_time - MATERIALIZE) / (GRIP - MATERIALIZE)
		_sword.position = _sword.position.lerp(_grip_target, t)
		_sword.rotation = lerpf(0.0, PI * 0.5 * player.facing, t)
		_sword.modulate.a = 1.0 - t
		if randf() < 0.6:
			_spawn_fragment(6.0, to_local(player.global_position + Vector2(10 * player.facing, -16)), true)
		_light.energy = lerpf(1.5, 0.6, t)
	elif _time < READY:
		# 6: lista.
		_light.energy = lerpf(0.6, 0.0, (_time - GRIP) / (READY - GRIP))
	else:
		done.emit()
		set_process(false)
	_update_fragments(delta)
	queue_redraw()


func _draw() -> void:
	# Líneas de datos verticales que suben (activación y manifestación).
	if _time < CONDENSE:
		var strength := clampf(_time / ACTIVATION, 0.0, 1.0) * (1.0 - clampf((_time - MANIFEST) / 0.6, 0.0, 1.0))
		for i in 7:
			var x := (i - 3) * 6.0 + sin(_time * 3.0 + i) * 2.0
			var length := 18.0 + 22.0 * absf(sin(_time * 5.0 + i * 1.3))
			draw_line(Vector2(x, 26), Vector2(x, 26 - length), Color(VIOLET, 0.6 * strength), 1.0)
	# Condensación: la línea central.
	if _time > MANIFEST - 0.2 and _time < MATERIALIZE:
		var glow := clampf((_time - (MANIFEST - 0.2)) / 0.4, 0.0, 1.0)
		draw_rect(Rect2(-1, -26, 2, 52), Color(LIGHT, 0.5 * glow))
	# Anillo del destello.
	if _flash > 0.0:
		draw_arc(Vector2.ZERO, 30.0 * (1.0 - _flash) + 8.0, 0.0, TAU, 24, Color(LIGHT, _flash), 2.0)
	for f in _fragments:
		var c: Color = f.color
		c.a *= clampf(f.life / 0.3, 0.0, 1.0)
		draw_rect(Rect2(f.pos.round(), f.size), c)


## Fragmento de código (un bloque pequeño). Si inward, viaja hacia el centro (o hacia "to").
func _spawn_fragment(radius: float, to := Vector2.ZERO, inward := false) -> void:
	var angle := randf() * TAU
	var start := to + Vector2(cos(angle), sin(angle)) * radius if inward else Vector2(cos(angle), sin(angle)) * randf_range(2.0, 8.0)
	var velocity := (to - start) * 3.0 if inward else Vector2(cos(angle), sin(angle) * 0.6 - 0.4) * radius * 1.2
	_fragments.append({
		"pos": start, "vel": velocity, "life": randf_range(0.4, 0.8),
		"size": Vector2([1, 1, 2, 3].pick_random(), [1, 2, 2].pick_random()),
		"color": [VIOLET, LIGHT, DEEP, Color.WHITE].pick_random(),
	})


func _update_fragments(delta: float) -> void:
	var condensing := _time >= MANIFEST and _time < MATERIALIZE
	for f in _fragments:
		if condensing:
			# Se juntan hacia la línea de la espada.
			f.vel = f.vel.lerp(Vector2(-f.pos.x * 6.0, -f.pos.y * 1.5), 0.2)
		f.pos += f.vel * delta
		f.vel *= 0.96
		f.life -= delta
	_fragments = _fragments.filter(func(f: Dictionary) -> bool: return f.life > 0.0)


func _burst(count: int) -> void:
	for i in count:
		var angle := TAU * i / count
		_fragments.append({
			"pos": Vector2.ZERO, "vel": Vector2(cos(angle), sin(angle)) * randf_range(50.0, 90.0),
			"life": randf_range(0.3, 0.6), "size": Vector2(2, 2), "color": [LIGHT, VIOLET].pick_random(),
		})


func _kai_pose(anim: StringName, seconds: float) -> void:
	var kai := player.get_node_or_null("Visual/Body/Kai")
	if kai and kai.has_method("play_pose"):
		kai.play_pose(anim, seconds)


func _shake() -> void:
	var room := player.owner as Room
	if room and room.camera and room.camera.has_method("shake"):
		room.camera.shake(2.0, 0.2)
