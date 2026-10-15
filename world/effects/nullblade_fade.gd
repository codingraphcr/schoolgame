class_name NullbladeFade
extends Node2D
## La Nullblade se va (al vencer al jefe del prólogo): aparece en la mano de Kai y parpadea cada vez
## más rápido, Kai la aprieta con más fuerza y la espada se deshace en partículas violetas hasta
## desaparecer (le quita el arma). try_summon(): Kai intenta invocarla otra vez y no pasa nada,
## solo unas chispas que se apagan.
## Uso: await NullbladeFade.play(jugador)  ·  await NullbladeFade.try_summon(jugador)

const SWORD := preload("res://assets/art/items/nullblade/nullblade_espada.png")
const DISSOLVE := preload("res://world/effects/pixel_dissolve.gdshader")
const VIOLET := Color("8a5cff")
const LIGHT := Color("d9ccff")
const DEEP := Color("4b2bd6")

var player: Player
var _sword: Sprite2D
var _particles: Array[Dictionary] = []
var _glow := 0.0


static func play(target: Player) -> void:
	var fade := NullbladeFade.new()
	fade.player = target
	target.add_child(fade)
	await fade._run()
	fade.queue_free()


static func try_summon(target: Player) -> void:
	var fade := NullbladeFade.new()
	fade.player = target
	target.add_child(fade)
	await fade._summon()
	fade.queue_free()


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	for p in _particles:
		p.vel += p.accel * delta
		p.pos += p.vel * delta
		p.life -= delta
	_particles = _particles.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
	queue_redraw()


func _run() -> void:
	# 1. Aparece en su mano y parpadea, cada vez más rápido.
	_sword = Sprite2D.new()
	_sword.texture = SWORD
	_sword.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sword.scale = Vector2.ONE * 0.32
	_sword.position = Vector2(11 * player.facing, -12)
	_sword.rotation = -0.4 * player.facing
	add_child(_sword)
	var material := ShaderMaterial.new()
	material.shader = DISSOLVE
	material.set_shader_parameter(&"edge_color", VIOLET)
	_sword.material = material
	Sfx.play(&"monitor_static", 1.4, -8.0)
	var elapsed := 0.0
	while elapsed < 1.3:
		var delta := get_process_delta_time()
		elapsed += delta
		var rate := lerpf(4.0, 22.0, elapsed / 1.3)
		_sword.modulate.a = 0.35 + 0.65 * absf(sin(elapsed * rate))
		if not await FrameWait.process(self):
			return
	# 2. Kai la aprieta con más fuerza: tiembla y brilla.
	_pose(&"ataque_1", 0.6)
	_sword.modulate.a = 1.0
	Sfx.play(&"reveal_grip", 0.7, -4.0)
	elapsed = 0.0
	while elapsed < 0.6:
		var delta := get_process_delta_time()
		elapsed += delta
		_sword.position = Vector2(11 * player.facing, -12) + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		_glow = elapsed / 0.6
		if not await FrameWait.process(self):
			return
	# 3. Se deshace en partículas violetas hasta desaparecer.
	Sfx.play(&"blade_shatter")
	player.combat.weapon = null
	elapsed = 0.0
	while elapsed < 0.9:
		var delta := get_process_delta_time()
		elapsed += delta
		material.set_shader_parameter(&"amount", clampf(elapsed / 0.9, 0.0, 1.0))
		_glow = 1.0 - elapsed / 0.9
		for i in 3:
			var at := _sword.position + Vector2(randf_range(-4.0, 4.0), randf_range(-14.0, 14.0)).rotated(_sword.rotation)
			_particles.append({ "pos": at, "vel": Vector2(randf_range(-15.0, 15.0), randf_range(-40.0, -10.0)),
				"accel": Vector2(0, -15.0), "life": randf_range(0.5, 1.0), "color": [VIOLET, LIGHT, DEEP].pick_random() })
		if not await FrameWait.process(self):
			return
	_sword.queue_free()
	await get_tree().create_timer(0.8).timeout


func _summon() -> void:
	_pose(&"ataque_1", 0.5)
	Sfx.play(&"error", 1.3, -8.0)
	var hand := Vector2(12 * player.facing, -14)
	for i in 8:
		var angle := randf_range(-PI, 0.0)
		_particles.append({ "pos": hand, "vel": Vector2(cos(angle), sin(angle)) * randf_range(10.0, 30.0),
			"accel": Vector2(0, 60.0), "life": randf_range(0.25, 0.45), "color": [VIOLET, LIGHT].pick_random() })
	await get_tree().create_timer(0.9).timeout


func _draw() -> void:
	if _glow > 0.0 and is_instance_valid(_sword):
		for i in 3:
			draw_circle(_sword.position, 8.0 + i * 4.0, Color(VIOLET, 0.12 * _glow))
	for p in _particles:
		var color: Color = p.color
		color.a *= clampf(p.life / 0.3, 0.0, 1.0)
		draw_rect(Rect2(p.pos.round(), Vector2(1, 1) if p.life < 0.3 else Vector2(2, 2)), color)


func _pose(anim: StringName, seconds: float) -> void:
	var kai := player.get_node_or_null("Visual/Body/Kai")
	if kai and kai.has_method("play_pose"):
		kai.play_pose(anim, seconds)
